import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

import 'package:batasph_mobile/config/config.dart';
import 'package:batasph_mobile/data/local/my_shared_pref.dart';
import 'package:batasph_mobile/data/remote/api_client.dart';
import 'package:batasph_mobile/pages/voice_chat/services/realtime_socket_client.dart';
import 'package:batasph_mobile/pages/voice_chat/services/realtime_socket_client_factory.dart';
import 'package:batasph_mobile/pages/voice_chat/services/stt_service.dart';
import 'package:batasph_mobile/pages/voice_chat/services/uplink_gate.dart';
import 'package:batasph_mobile/pages/voice_chat/services/voice_audio_route.dart';
import 'package:batasph_mobile/pages/voice_chat/services/voice_echo_probe.dart';
import 'package:batasph_mobile/utils/logger_util.dart';

void _d(String msg) => BatasphLogger.debug('[STT] $msg');

/// Speech-to-text over the OpenAI Realtime transcription API.
///
/// Two lifecycles:
///
/// * Per utterance (`continuous: false`, the original): mint a secret,
///   connect, stream the mic; the server VAD ends the turn, the final
///   transcript arrives, the socket is torn down. Every turn pays the
///   mint + connect (~0.5–1 s), during which the mic is not open.
///
/// * Continuous (`continuous: true`, 2026-09-18): one socket and one
///   recorder for the whole conversation. After a final transcript the
///   session stays up and the next utterance is simply the next segment,
///   so listening resumes the instant a reply ends. While the assistant is
///   itself producing sound the controller calls [setMuted]: the recorder
///   keeps running but no audio is sent, so the assistant never transcribes
///   its own voice and no audio is billed. A long silence ([_idleTimeout])
///   closes the session and reports [onIdle]. An unexpected socket close is
///   reconnected once, silently, before it becomes an error.
class RealtimeSttService implements SttService {
  RealtimeSttService({this.continuous = false});

  /// See the class doc. The controller passes true; the Whisper fallback
  /// path never constructs this class.
  final bool continuous;

  static const int _sampleRate = 24000;
  static const Duration _speechStartTimeout = Duration(seconds: 5);

  /// How long listening waits on an empty room before closing the session.
  /// BatasPH keeps 45s (Memori uses 10s for its tap-to-speak screen): a call
  /// already asks "nandiyan ka pa ba?" after 10s of silence and says goodbye
  /// 8s later, and must not lose its microphone underneath that.
  static const Duration _idleTimeout = Duration(seconds: 45);
  static const Duration _maxRecordingDuration = Duration(seconds: 45);
  static const Duration _minimumEndOfSpeechDelay = Duration(milliseconds: 700);
  static const Duration _endOfSpeechFrontendCushion = Duration(
    milliseconds: 200,
  );

  /// Minimum remaining lifetime for a client secret to be usable.
  /// If less than this remains, fetch a new one rather than risk a mid-connect expiry.
  static const Duration _tokenExpiryBuffer = Duration(seconds: 5);

  @visibleForTesting
  static Duration resolveEndOfSpeechDelay(int configuredSeconds) {
    final configuredDelay = Duration(
      milliseconds: math.max(0, configuredSeconds) * 1000,
    );
    final softenedDelay = configuredDelay - _endOfSpeechFrontendCushion;
    if (softenedDelay < _minimumEndOfSpeechDelay) {
      return _minimumEndOfSpeechDelay;
    }
    return softenedDelay;
  }

  @visibleForTesting
  static int resolveSilenceDurationMs(int configuredSeconds) =>
      resolveEndOfSpeechDelay(configuredSeconds).inMilliseconds;

  AudioRecorder? _recorder;
  StreamSubscription<Uint8List>? _audioSubscription;
  StreamSubscription<Object?>? _socketSubscription;
  RealtimeSocketClient? _socket;
  Timer? _speechStartWatchdog;
  Timer? _idleTimer;
  Timer? _maxRecordingTimer;

  @override
  SttResultCallback? onResult;
  @override
  SttErrorCallback? onError;
  @override
  SttTranscribingCallback? onTranscribing;
  @override
  SttSpeechStartedCallback? onSpeechStarted;
  @override
  SttIdleCallback? onIdle;
  @override
  SttAudioLevelCallback? onAudioLevel;

  bool _isActive = false;
  bool _muted = false;
  bool _awaitingFinalTranscript = false;
  bool _finalResultEmitted = false;
  bool _hasDetectedSpeech = false;
  bool _expectedSocketClose = false;
  bool _reconnecting = false;
  int _sessionId = 0;
  int _chunksSent = 0;
  int _chunksDropped = 0;

  /// Frames actually uplinked since the last mute change. Tells the
  /// difference between 'the mic was open' and 'the mic was open and we
  /// paid for it'.
  int _framesSentThisTurn = 0;
  int _framesHeldThisTurn = 0;
  final _uplinkGate = UplinkGate();
  bool _gated = false;
  String _partialTranscript = '';
  String? _activeItemId;
  String? _lastCompletedItemId;

  @override
  bool get isActive => _isActive;

  @override
  bool get supportsContinuousListening => continuous;

  @override
  void setMuted(bool muted, {bool preserveBuffer = false}) {
    if (_muted == muted) return;
    _muted = muted;
    _d(
      'RealtimeSTT.setMuted($muted, preserveBuffer: $preserveBuffer) | isActive=$_isActive',
    );
    BatasphLogger.log(
      '[BARGE] mic ${muted ? 'closed' : 'OPEN'} '
      '${preserveBuffer ? '(buffer kept)' : '(buffer cleared)'} '
      'uplinked=$_framesSentThisTurn frames since last change',
    );
    _framesSentThisTurn = 0;
    if (!continuous || !_isActive) return;
    // The idle clock only runs while the user could actually be heard.
    if (muted) {
      _cancelIdleTimer();
      if (!preserveBuffer) {
        // Drop whatever uncommitted audio the server still holds, so a
        // half-sentence cut off by the mute is not glued onto the next one
        // when we unmute.
        _socket?.sendText(jsonEncode({'type': 'input_audio_buffer.clear'}));
        _awaitingFinalTranscript = false;
        _partialTranscript = '';
        _activeItemId = null;
      }
    } else {
      _armIdleTimer(_sessionId);
    }
  }

  @override
  Future<void> warmUp() async {}

  @override
  Future<void> startSession() async {
    _d('RealtimeSTT.startSession() called | isActive=$_isActive');
    if (_isActive) {
      _d('RealtimeSTT.startSession() already active, returning');
      return;
    }

    final sessionId = ++_sessionId;
    _isActive = true;
    _muted = false;
    _awaitingFinalTranscript = false;
    _finalResultEmitted = false;
    _hasDetectedSpeech = false;
    _expectedSocketClose = false;
    _partialTranscript = '';
    _activeItemId = null;
    _lastCompletedItemId = null;
    _cancelSpeechStartWatchdog();
    _cancelIdleTimer();
    _cancelMaxRecordingTimer();

    try {
      final socket = await _connect(sessionId);
      if (socket == null) return; // cancelled during connect

      final recorder = AudioRecorder();
      _recorder = recorder;
      final stream = await recorder.startStream(
        RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _sampleRate,
          numChannels: 1,
          // The phone is typically at arm's length, not at the mouth: let
          // the platform AGC lift quiet input before it reaches the VAD
          // (2026-09-18: speech at ~1 ft was barely picked up without it).
          autoGain: true,
          // The mic now stays open while the assistant plays its thinking
          // loop (continuous mode): let the platform cancel what the
          // speaker feeds back into the mic.
          echoCancel: true,
          // Continuous conversation: the mic must never be paused by audio
          // focus. The default (pause) makes the recorder request focus and
          // pause on loss — which happens the moment the reply TTS starts —
          // and it only resumes on a GAIN that never comes, so every turn
          // after the first reply heard nothing (2026-09-18). With none the
          // recorder does not take part in focus at all.
          audioInterruption: AudioInterruptionMode.none,
          // The capture half of the audio route. Its Android globals are
          // shared with the reply player — see VoiceAudioRoute for why the
          // two must not be set independently.
          androidConfig: VoiceAudioRoute.recordConfig(),
        ),
      );
      if (sessionId != _sessionId) {
        _d('RealtimeSTT.startSession() cancelled during recorder start');
        await recorder.stop();
        recorder.dispose();
        return;
      }

      _audioSubscription = stream.listen(
        (chunk) {
          if (!_isActive) return;
          // Before the mute check on purpose: a muted frame is still a
          // measurement of what the microphone hears while we speak, and it
          // costs nothing because the frame is not sent.
          final dbfs = _reportAudioLevel(chunk);
          if (continuous ? _muted : _awaitingFinalTranscript) {
            if (++_chunksDropped % 100 == 0) {
              _d('RealtimeSTT mic: $_chunksDropped chunks dropped (muted)');
            }
            return;
          }
          if (_gated) {
            final wasOpen = _uplinkGate.isOpen;
            final toSend = _uplinkGate.offer(chunk, dbfs);
            if (toSend.isEmpty) {
              if (wasOpen && _uplinkGate.lastCloseWasForced) {
                BatasphLogger.log(
                  '[BARGE] uplink forced shut — the room stayed above its own '
                  'threshold, re-measuring',
                );
              }
              _framesHeldThisTurn++;
              return;
            }
            if (!wasOpen) {
              BatasphLogger.log(
                '[BARGE] uplink opened | level=${dbfs.toStringAsFixed(1)}dBFS '
                'floor=${_uplinkGate.floorDbfs.toStringAsFixed(1)}dBFS '
                'held=$_framesHeldThisTurn frames, ${toSend.length} flushed',
              );
            }
            for (final frame in toSend) {
              _sendFrame(frame);
            }
            return;
          }
          _sendFrame(chunk);
        },
        onError: (Object error) {
          _handleSocketError(sessionId, 'Microphone stream failed: $error');
        },
      );

      final silenceSeconds = AppConfig.voiceSilenceSeconds;
      final silenceDurationMs = resolveSilenceDurationMs(silenceSeconds);
      BatasphLogger.log(
        '[STT] Streaming started '
        'sampleRate=${_sampleRate}Hz silence=${silenceDurationMs}ms '
        'continuous=$continuous',
      );
      // What the route actually resolved to. Read this before trusting any
      // echo figure below it: a leak measured while the route failed to
      // apply says nothing about whether the route works.
      BatasphLogger.log('[BARGE] route ${VoiceAudioRoute.describe()}');

      if (continuous) {
        _armIdleTimer(sessionId);
      } else {
        _armSpeechStartWatchdog(sessionId);
        _armMaxRecordingTimer(sessionId);
      }
    } catch (e) {
      _d('RealtimeSTT.startSession() FAILED: $e');
      BatasphLogger.error('[STT] Failed to start session: $e');
      await _teardown(incrementSession: false);
      onError?.call('Failed to start realtime voice chat');
    }
  }

  /// Mints a secret and opens the socket for [sessionId]. Returns null when
  /// the session was cancelled meanwhile (each await is followed by a
  /// session check; a cancelled start is a no-op, not an error).
  Future<RealtimeSocketClient?> _connect(int sessionId) async {
    final sessionInfo = await _createRealtimeSessionInfo();
    if (sessionId != _sessionId) return null;

    if (_isTokenExpired(sessionInfo)) {
      throw Exception('Client secret expired before WebSocket connect');
    }

    final socket = createRealtimeSocketClient();
    _socket = socket;
    _d(
      'RealtimeSTT connecting to ${sessionInfo.url} '
      'expiresAt=${sessionInfo.expiresAt}',
    );
    await socket.connect(
      sessionInfo.url,
      headers: {'Authorization': 'Bearer ${sessionInfo.clientSecret}'},
    );
    if (sessionId != _sessionId) {
      // Teardown already ran while we were connecting; the socket it
      // closed was not yet open, so this one is ours to close.
      _d('RealtimeSTT cancelled during connect');
      await socket.close();
      return null;
    }

    _socketSubscription = socket.messages.listen(
      (message) => _handleSocketMessage(sessionId, message),
      onError: (Object error) {
        _handleSocketError(sessionId, 'Realtime transcription failed: $error');
      },
      onDone: () {
        _handleSocketDone(sessionId);
      },
    );
    return socket;
  }

  @override
  Future<void> stopSession() async {
    _d(
      'RealtimeSTT.stopSession() called | '
      'isActive=$_isActive awaitingFinal=$_awaitingFinalTranscript',
    );
    if (!_isActive || _awaitingFinalTranscript) {
      return;
    }

    _awaitingFinalTranscript = true;
    _cancelSpeechStartWatchdog();
    _cancelMaxRecordingTimer();
    if (!continuous) {
      await _stopStreamingAudio();
    }
    onTranscribing?.call();
    _socket?.sendText(jsonEncode({'type': 'input_audio_buffer.commit'}));
  }

  @override
  Future<void> cancelSession() async {
    _d('RealtimeSTT.cancelSession() called | isActive=$_isActive');
    _sessionId++;
    await _teardown(incrementSession: false);
  }

  void _handleSocketMessage(int sessionId, Object? message) {
    if (sessionId != _sessionId || message == null) {
      return;
    }

    final text = message is String
        ? message
        : utf8.decode(message as List<int>);
    final payload = jsonDecode(text);
    if (payload is! Map<String, dynamic>) {
      return;
    }

    final type = payload['type'] as String?;
    if (type != 'conversation.item.input_audio_transcription.delta') {
      _d('RealtimeSTT ← $type');
    }
    switch (type) {
      case 'input_audio_buffer.speech_started':
        _hasDetectedSpeech = true;
        _cancelSpeechStartWatchdog();
        if (continuous) {
          _cancelIdleTimer();
          _armMaxRecordingTimer(sessionId);
        }
        onSpeechStarted?.call();
        break;
      case 'input_audio_buffer.speech_stopped':
        unawaited(_handleSpeechStopped(sessionId));
        break;
      case 'conversation.item.input_audio_transcription.delta':
        _handleTranscriptDelta(payload);
        break;
      case 'conversation.item.input_audio_transcription.completed':
        unawaited(_handleTranscriptCompleted(sessionId, payload));
        break;
      case 'conversation.item.input_audio_transcription.failed':
      case 'error':
        _handleSocketError(sessionId, _extractRealtimeErrorMessage(payload));
        break;
    }
  }

  void _handleTranscriptDelta(Map<String, dynamic> payload) {
    final itemId = payload['item_id'] as String?;
    final delta = payload['delta'] as String? ?? '';
    if (itemId == null || delta.isEmpty) {
      return;
    }

    if (_activeItemId != itemId) {
      _activeItemId = itemId;
      _partialTranscript = '';
    }

    _partialTranscript += delta;
    onResult?.call(_partialTranscript.trim(), false);
  }

  Future<void> _handleTranscriptCompleted(
    int sessionId,
    Map<String, dynamic> payload,
  ) async {
    if (sessionId != _sessionId) return;

    final transcript = (payload['transcript'] as String? ?? '').trim();

    if (!continuous) {
      if (_finalResultEmitted) return;
      _finalResultEmitted = true;
      BatasphLogger.log('[STT] Final transcript: $transcript');
      onResult?.call(transcript, true);
      await _teardown(incrementSession: true);
      return;
    }

    // Continuous: one final per item, then the session simply carries on.
    final itemId = payload['item_id'] as String?;
    if (itemId != null && itemId == _lastCompletedItemId) return;
    _lastCompletedItemId = itemId;
    _awaitingFinalTranscript = false;
    _partialTranscript = '';
    _activeItemId = null;
    _hasDetectedSpeech = false;
    _cancelMaxRecordingTimer();
    if (!_muted) _armIdleTimer(sessionId);
    BatasphLogger.log('[STT] Final transcript: $transcript');
    onResult?.call(transcript, true);
  }

  Future<void> _handleSpeechStopped(int sessionId) async {
    if (sessionId != _sessionId || _awaitingFinalTranscript) {
      return;
    }

    _awaitingFinalTranscript = true;
    _cancelMaxRecordingTimer();
    if (!continuous) {
      // Per-utterance: nothing more is wanted from the mic this turn.
      await _stopStreamingAudio();
    }
    onTranscribing?.call();
  }

  void _handleSocketDone(int sessionId) {
    _d(
      'RealtimeSTT socket closed | session=$sessionId current=$_sessionId expected=$_expectedSocketClose active=$_isActive',
    );
    if (sessionId != _sessionId || _expectedSocketClose) {
      return;
    }

    if (continuous && _isActive && !_reconnecting) {
      unawaited(_reconnect(sessionId));
      return;
    }

    if (_isActive || _awaitingFinalTranscript) {
      _handleSocketError(sessionId, 'Realtime transcription disconnected');
    }
  }

  /// A continuous session can outlive its socket (server-side limits,
  /// network blips). Reconnect once with a fresh secret, keeping the
  /// recorder running; if that fails it is a real error.
  Future<void> _reconnect(int sessionId) async {
    _reconnecting = true;
    BatasphLogger.log('[STT] Socket closed mid-conversation, reconnecting');
    // An utterance whose final transcript was still pending is lost with the
    // old socket; the controller is told so with an empty final, which it
    // treats as "back to listening" instead of waiting forever.
    final lostPendingTranscript = _awaitingFinalTranscript;
    try {
      await _socketSubscription?.cancel();
      _socketSubscription = null;
      _socket = null;
      _awaitingFinalTranscript = false;
      _partialTranscript = '';
      _activeItemId = null;
      final socket = await _connect(sessionId);
      if (socket == null) return; // cancelled meanwhile
      BatasphLogger.log('[STT] Reconnected');
      if (!_muted) _armIdleTimer(sessionId);
      if (lostPendingTranscript) onResult?.call('', true);
    } catch (e) {
      _handleSocketError(sessionId, 'Realtime transcription disconnected: $e');
    } finally {
      _reconnecting = false;
    }
  }

  void _handleSocketError(int sessionId, String message) {
    if (sessionId != _sessionId) {
      return;
    }

    BatasphLogger.error('[STT] $message');
    _sessionId++;
    unawaited(_teardown(incrementSession: false));
    onError?.call(message);
  }

  bool _isTokenExpired(_RealtimeSessionInfo info) {
    if (info.expiresAt <= 0) return false;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return info.expiresAt - now < _tokenExpiryBuffer.inSeconds;
  }

  String _extractRealtimeErrorMessage(Map<String, dynamic> payload) {
    final error = payload['error'];
    if (error is Map<String, dynamic>) {
      final message = error['message'] as String?;
      if (message != null && message.trim().isNotEmpty) {
        return message.trim();
      }
    }
    return 'Realtime transcription failed';
  }

  Future<_RealtimeSessionInfo> _createRealtimeSessionInfo() async {
    final languages = MySharedPref.getSpeechLanguages();
    final silenceDurationMs = resolveSilenceDurationMs(
      AppConfig.voiceSilenceSeconds,
    );
    final response = await ApiClient().client.post(
      '/realtime-transcription/session',
      data: {'languages': languages, 'silenceDurationMs': silenceDurationMs},
      options: dio.Options(receiveTimeout: const Duration(seconds: 30)),
    );
    return _RealtimeSessionInfo.fromJson(response.data as Map<String, dynamic>);
  }

  void _sendFrame(Uint8List frame) {
    if (++_chunksSent % 100 == 0) {
      _d(
        'RealtimeSTT mic: $_chunksSent chunks sent | socket=${_socket != null} muted=$_muted',
      );
    }
    _framesSentThisTurn++;
    _socket?.sendText(
      jsonEncode({
        'type': 'input_audio_buffer.append',
        'audio': base64Encode(frame),
      }),
    );
  }

  double _reportAudioLevel(Uint8List chunk) {
    final dbfs = VoiceEchoProbe.rmsDbfs(chunk);
    onAudioLevel?.call(dbfs);
    return dbfs;
  }

  @override
  void setUplinkGate(bool gated) {
    if (_gated == gated) return;
    _gated = gated;
    if (gated) {
      _framesHeldThisTurn = 0;
      _uplinkGate.reset();
    } else if (_framesHeldThisTurn > 0) {
      BatasphLogger.log(
        '[BARGE] uplink ungated | $_framesHeldThisTurn frames were held back',
      );
    }
  }

  Future<void> _stopStreamingAudio() async {
    _cancelSpeechStartWatchdog();
    await _audioSubscription?.cancel();
    _audioSubscription = null;

    try {
      await _recorder?.stop();
    } catch (e) {
      _d('RealtimeSTT recorder.stop threw during teardown (ignored): $e');
    }
    _recorder?.dispose();
    _recorder = null;
  }

  Future<void> _teardown({required bool incrementSession}) async {
    _isActive = false;
    _muted = false;
    _awaitingFinalTranscript = false;
    _cancelSpeechStartWatchdog();
    _cancelIdleTimer();
    _cancelMaxRecordingTimer();
    await _stopStreamingAudio();
    await _socketSubscription?.cancel();
    _socketSubscription = null;
    _expectedSocketClose = true;
    await _socket?.close();
    _socket = null;
    _partialTranscript = '';
    _activeItemId = null;
    _lastCompletedItemId = null;
    _hasDetectedSpeech = false;
    _finalResultEmitted = false;
    if (incrementSession) {
      _sessionId++;
    }
  }

  void _armSpeechStartWatchdog(int sessionId) {
    _cancelSpeechStartWatchdog();
    _speechStartWatchdog = Timer(_speechStartTimeout, () async {
      if (!_isActive || sessionId != _sessionId || _hasDetectedSpeech) {
        return;
      }

      BatasphLogger.log('[STT] Speech-start watchdog fired');
      await cancelSession();
      onResult?.call('', true);
    });
  }

  void _cancelSpeechStartWatchdog() {
    _speechStartWatchdog?.cancel();
    _speechStartWatchdog = null;
  }

  /// Continuous mode: a long silence while unmuted closes the session so a
  /// forgotten phone does not stream (and pay) indefinitely.
  void _armIdleTimer(int sessionId) {
    _cancelIdleTimer();
    _idleTimer = Timer(_idleTimeout, () async {
      if (!_isActive || sessionId != _sessionId || _muted) {
        return;
      }
      BatasphLogger.log(
        '[STT] Idle for ${_idleTimeout.inSeconds}s, closing session',
      );
      await cancelSession();
      onIdle?.call();
    });
  }

  void _cancelIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = null;
  }

  void _armMaxRecordingTimer(int sessionId) {
    _cancelMaxRecordingTimer();
    _maxRecordingTimer = Timer(_maxRecordingDuration, () {
      if (!_isActive || sessionId != _sessionId) {
        return;
      }

      BatasphLogger.log('[STT] Max recording duration reached');
      if (continuous) {
        // Force the server to segment a monologue; the session carries on.
        _socket?.sendText(jsonEncode({'type': 'input_audio_buffer.commit'}));
      } else {
        unawaited(stopSession());
      }
    });
  }

  void _cancelMaxRecordingTimer() {
    _maxRecordingTimer?.cancel();
    _maxRecordingTimer = null;
  }

  @override
  Future<void> dispose() async {
    _d('RealtimeSTT.dispose() called');
    _sessionId++;
    await _teardown(incrementSession: false);
    onResult = null;
    onError = null;
    onTranscribing = null;
    onSpeechStarted = null;
    onIdle = null;
    onAudioLevel = null;
  }
}

class _RealtimeSessionInfo {
  _RealtimeSessionInfo({
    required this.clientSecret,
    required this.expiresAt,
    required this.url,
  });

  final String clientSecret;
  final int expiresAt;
  final String url;

  factory _RealtimeSessionInfo.fromJson(Map<String, dynamic> json) {
    return _RealtimeSessionInfo(
      clientSecret: json['clientSecret'] as String? ?? '',
      expiresAt: json['expiresAt'] as int? ?? 0,
      url: json['url'] as String? ?? '',
    );
  }
}
