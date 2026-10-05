import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

import 'package:batasph_mobile/data/local/my_shared_pref.dart';
import 'package:batasph_mobile/data/remote/api_client.dart';
import 'package:batasph_mobile/pages/voice_chat/services/realtime_socket_client.dart';
import 'package:batasph_mobile/pages/voice_chat/services/realtime_socket_client_factory.dart';
import 'package:batasph_mobile/pages/voice_chat/services/stt_service.dart';
import 'package:batasph_mobile/utils/logger_util.dart';

/// Speech-to-text over the OpenAI Realtime transcription API, one socket and
/// one recorder for the whole call.
///
/// The backend mints a short-lived client secret (`POST
/// /realtime-transcription/session`); the phone streams PCM16 straight to
/// OpenAI and the server VAD segments turns. After a final transcript the
/// session stays up and the next utterance is simply the next segment, so
/// listening resumes the instant a reply ends. While the assistant is itself
/// producing sound the controller calls [setMuted]: the recorder keeps
/// running but no audio is sent, so the assistant never transcribes its own
/// voice. A long silence ([_idleTimeout]) closes the session and reports
/// [onIdle]. An unexpected socket close is reconnected once, silently,
/// before it becomes an error.
class RealtimeSttService implements SttService {
  static const int _sampleRate = 24000;
  static const Duration _idleTimeout = Duration(seconds: 45);
  static const Duration _maxRecordingDuration = Duration(seconds: 45);
  static const Duration _minimumEndOfSpeechDelay = Duration(milliseconds: 700);
  static const Duration _endOfSpeechFrontendCushion = Duration(
    milliseconds: 200,
  );

  /// Minimum remaining lifetime for a client secret to be usable. Below this
  /// a fresh one is minted rather than risk a mid-connect expiry.
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

  bool _isActive = false;
  bool _muted = false;
  bool _awaitingFinalTranscript = false;
  bool _expectedSocketClose = false;
  bool _reconnecting = false;
  int _sessionId = 0;
  int _chunksSent = 0;
  int _chunksDropped = 0;
  String _partialTranscript = '';
  String? _activeItemId;
  String? _lastCompletedItemId;

  @override
  bool get isActive => _isActive;

  @override
  bool get supportsContinuousListening => true;

  @override
  void setMuted(bool muted) {
    if (_muted == muted) return;
    _muted = muted;
    BatasphLogger.debug('[STT] setMuted($muted) | active=$_isActive');
    if (!_isActive) return;
    // The idle clock only runs while the user could actually be heard.
    if (muted) {
      _cancelIdleTimer();
      // Drop whatever uncommitted audio the server still holds, so a
      // half-sentence cut off by the mute is not glued onto the next one
      // when we unmute.
      _socket?.sendText(jsonEncode({'type': 'input_audio_buffer.clear'}));
      _awaitingFinalTranscript = false;
      _partialTranscript = '';
      _activeItemId = null;
    } else {
      _armIdleTimer(_sessionId);
    }
  }

  @override
  Future<void> warmUp() async {}

  @override
  Future<void> startSession() async {
    if (_isActive) {
      return;
    }

    final sessionId = ++_sessionId;
    _isActive = true;
    // `_muted` is deliberately NOT reset: a caller opening the session
    // while its own audio plays pre-mutes so the recorder's first chunks
    // are dropped rather than sent. Teardown resets it.
    _awaitingFinalTranscript = false;
    _expectedSocketClose = false;
    _partialTranscript = '';
    _activeItemId = null;
    _lastCompletedItemId = null;
    _cancelIdleTimer();
    _cancelMaxRecordingTimer();
    final stopwatch = Stopwatch()..start();

    try {
      final socket = await _connect(sessionId);
      if (socket == null) return; // cancelled during connect

      final recorder = AudioRecorder();
      _recorder = recorder;
      final stream = await recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _sampleRate,
          numChannels: 1,
          // The phone is typically at arm's length, not at the mouth: let
          // the platform AGC lift quiet input before it reaches the VAD.
          autoGain: true,
          // The mic stays open while the thinking loop plays: let the
          // platform cancel what the speaker feeds back into the mic.
          echoCancel: true,
          // The mic must never be paused by audio focus. The default (pause)
          // makes the recorder pause the moment the reply TTS takes focus
          // and it only resumes on a GAIN that never comes.
          audioInterruption: AudioInterruptionMode.none,
        ),
      );
      if (sessionId != _sessionId) {
        await recorder.stop();
        recorder.dispose();
        return;
      }

      _audioSubscription = stream.listen(
        (chunk) {
          if (!_isActive) return;
          if (_muted) {
            if (++_chunksDropped % 200 == 0) {
              BatasphLogger.debug(
                '[STT] mic: $_chunksDropped chunks dropped (muted)',
              );
            }
            return;
          }
          if (++_chunksSent % 200 == 0) {
            BatasphLogger.debug('[STT] mic: $_chunksSent chunks sent');
          }
          _socket?.sendText(
            jsonEncode({
              'type': 'input_audio_buffer.append',
              'audio': base64Encode(chunk),
            }),
          );
        },
        onError: (Object error) {
          _handleSocketError(sessionId, 'Microphone stream failed: $error');
        },
      );

      final silenceSeconds = MySharedPref.getVoiceSilenceSeconds();
      BatasphLogger.log(
        '[STT] Realtime session open | session=$sessionId'
        ' | ${stopwatch.elapsedMilliseconds}ms'
        ' | sampleRate=${_sampleRate}Hz'
        ' | silence=${resolveSilenceDurationMs(silenceSeconds)}ms',
      );
      _armIdleTimer(sessionId);
    } catch (error, stackTrace) {
      BatasphLogger.error(
        '[STT] Failed to start realtime session | session=$sessionId'
        ' | ${stopwatch.elapsedMilliseconds}ms',
        error: error,
        stackTrace: stackTrace,
      );
      await _teardown();
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
      throw StateError('Client secret expired before WebSocket connect');
    }

    final socket = createRealtimeSocketClient();
    _socket = socket;
    BatasphLogger.debug(
      '[STT] Connecting ${sessionInfo.url} | expiresAt=${sessionInfo.expiresAt}',
    );
    await socket.connect(
      sessionInfo.url,
      headers: {'Authorization': 'Bearer ${sessionInfo.clientSecret}'},
    );
    if (sessionId != _sessionId) {
      // Teardown already ran while we were connecting; the socket it
      // closed was not yet open, so this one is ours to close.
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
    if (!_isActive || _awaitingFinalTranscript) {
      return;
    }

    _awaitingFinalTranscript = true;
    _cancelMaxRecordingTimer();
    onTranscribing?.call();
    _socket?.sendText(jsonEncode({'type': 'input_audio_buffer.commit'}));
  }

  @override
  Future<void> cancelSession() async {
    if (_isActive) {
      BatasphLogger.log(
        '[STT] Realtime session cancelled | session=$_sessionId',
      );
    }
    _sessionId++;
    await _teardown();
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
    switch (type) {
      case 'input_audio_buffer.speech_started':
        BatasphLogger.log('[STT] Speech started | session=$sessionId');
        _cancelIdleTimer();
        _armMaxRecordingTimer(sessionId);
        onSpeechStarted?.call();
      case 'input_audio_buffer.speech_stopped':
        BatasphLogger.log('[STT] Speech stopped | session=$sessionId');
        _handleSpeechStopped(sessionId);
      case 'conversation.item.input_audio_transcription.delta':
        _handleTranscriptDelta(payload);
      case 'conversation.item.input_audio_transcription.completed':
        _handleTranscriptCompleted(sessionId, payload);
      case 'conversation.item.input_audio_transcription.failed':
      case 'error':
        _handleSocketError(sessionId, _extractRealtimeErrorMessage(payload));
      default:
        BatasphLogger.debug('[STT] <- $type');
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

  void _handleTranscriptCompleted(int sessionId, Map<String, dynamic> payload) {
    if (sessionId != _sessionId) return;

    final transcript = (payload['transcript'] as String? ?? '').trim();

    // One final per item, then the session simply carries on.
    final itemId = payload['item_id'] as String?;
    if (itemId != null && itemId == _lastCompletedItemId) return;
    _lastCompletedItemId = itemId;
    _awaitingFinalTranscript = false;
    _partialTranscript = '';
    _activeItemId = null;
    _cancelMaxRecordingTimer();
    if (!_muted) _armIdleTimer(sessionId);
    BatasphLogger.log(
      '[STT] Final transcript | session=$sessionId | chars=${transcript.length}',
    );
    onResult?.call(transcript, true);
  }

  void _handleSpeechStopped(int sessionId) {
    if (sessionId != _sessionId || _awaitingFinalTranscript) {
      return;
    }

    _awaitingFinalTranscript = true;
    _cancelMaxRecordingTimer();
    onTranscribing?.call();
  }

  void _handleSocketDone(int sessionId) {
    if (sessionId != _sessionId || _expectedSocketClose) {
      return;
    }

    if (_isActive && !_reconnecting) {
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
    BatasphLogger.warning(
      '[STT] Socket closed mid-call, reconnecting | session=$sessionId',
    );
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
      BatasphLogger.log('[STT] Reconnected | session=$sessionId');
      if (!_muted) _armIdleTimer(sessionId);
      if (lostPendingTranscript) onResult?.call('', true);
    } catch (error, stackTrace) {
      BatasphLogger.error(
        '[STT] Reconnect failed | session=$sessionId',
        error: error,
        stackTrace: stackTrace,
      );
      _handleSocketError(sessionId, 'Realtime transcription disconnected');
    } finally {
      _reconnecting = false;
    }
  }

  void _handleSocketError(int sessionId, String message) {
    if (sessionId != _sessionId) {
      return;
    }

    BatasphLogger.error('[STT] $message | session=$sessionId');
    _sessionId++;
    unawaited(_teardown());
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
      MySharedPref.getVoiceSilenceSeconds(),
    );
    final response = await ApiClient().client.post(
      '/realtime-transcription/session',
      data: {'languages': languages, 'silenceDurationMs': silenceDurationMs},
      options: dio.Options(receiveTimeout: const Duration(seconds: 30)),
    );
    return _RealtimeSessionInfo.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> _stopStreamingAudio() async {
    await _audioSubscription?.cancel();
    _audioSubscription = null;

    try {
      await _recorder?.stop();
    } catch (error) {
      BatasphLogger.debug('[STT] recorder.stop threw during teardown: $error');
    }
    _recorder?.dispose();
    _recorder = null;
  }

  Future<void> _teardown() async {
    _isActive = false;
    _muted = false;
    _awaitingFinalTranscript = false;
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
  }

  /// A long silence while unmuted closes the session so a forgotten phone
  /// does not stream (and pay) indefinitely.
  void _armIdleTimer(int sessionId) {
    _cancelIdleTimer();
    _idleTimer = Timer(_idleTimeout, () async {
      if (!_isActive || sessionId != _sessionId || _muted) {
        return;
      }
      BatasphLogger.log(
        '[STT] Idle for ${_idleTimeout.inSeconds}s, closing session'
        ' | session=$sessionId',
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
      BatasphLogger.log(
        '[STT] Max recording ${_maxRecordingDuration.inSeconds}s reached,'
        ' forcing segment | session=$sessionId',
      );
      // Force the server to segment a monologue; the session carries on.
      _socket?.sendText(jsonEncode({'type': 'input_audio_buffer.commit'}));
    });
  }

  void _cancelMaxRecordingTimer() {
    _maxRecordingTimer?.cancel();
    _maxRecordingTimer = null;
  }

  @override
  Future<void> dispose() async {
    _sessionId++;
    await _teardown();
    onResult = null;
    onError = null;
    onTranscribing = null;
    onSpeechStarted = null;
    onIdle = null;
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
