import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'dart:convert';

import 'package:batasph_mobile/config/config.dart';
import 'package:batasph_mobile/data/local/my_shared_pref.dart';
import 'package:batasph_mobile/data/remote/api_client.dart';
import 'package:batasph_mobile/pages/voice_chat/services/stt_service.dart';
import 'package:batasph_mobile/pages/voice_chat/services/whisper_turn_detector.dart';
import 'package:batasph_mobile/utils/logger_util.dart';

void _d(String msg) => BatasphLogger.debug('[STT] $msg');

/// Speech-to-text using OpenAI Whisper via the backend `/transcribe` endpoint.
///
/// Records audio to a temp file, monitors amplitude for silence detection,
/// then sends the file to the backend for Whisper transcription.
/// Best for multi-language / code-switching (e.g. Taglish).
class WhisperSttService implements SttService {
  static const double _silenceThresholdDb = -45.0;
  static const int _sampleRate = 16000;
  static const int _bitRate = 32000;
  static const Duration _amplitudeInterval = Duration(milliseconds: 120);
  static const Duration _speechStartTimeout = Duration(seconds: 5);
  static const Duration _maxRecordingDuration = Duration(seconds: 45);
  static const Duration _minimumEndOfSpeechDelay = Duration(milliseconds: 700);
  static const Duration _endOfSpeechFrontendCushion = Duration(
    milliseconds: 200,
  );

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
  static int resolveSilenceWindowSamples(
    int configuredSeconds, {
    Duration amplitudeInterval = _amplitudeInterval,
  }) {
    final endOfSpeechDelay = resolveEndOfSpeechDelay(configuredSeconds);
    return math.max(
      1,
      (endOfSpeechDelay.inMilliseconds / amplitudeInterval.inMilliseconds)
          .round(),
    );
  }

  AudioRecorder? _recorder;
  String? _recordingPath;
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  WhisperTurnDetector? _turnDetector;
  Timer? _speechStartWatchdog;
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

  /// The fallback path does not meter: it only runs when realtime STT has
  /// already failed, and the echo measurement is about the continuous session.
  @override
  SttAudioLevelCallback? onAudioLevel;

  // One recording per utterance; nothing to mute between turns.
  @override
  bool get supportsContinuousListening => false;
  @override
  void setMuted(bool muted, {bool preserveBuffer = false}) {}

  /// The fallback records one utterance at a time and never runs during the
  /// assistant's turn, so there is nothing to gate.
  @override
  void setUplinkGate(bool gated) {}

  bool _isActive = false;
  int _sessionId = 0;
  @override
  bool get isActive => _isActive;

  @override
  Future<void> warmUp() async {
    // No pre-warming needed — Whisper uses the backend directly.
  }

  @override
  Future<void> startSession() async {
    _d('WhisperSTT.startSession() called | isActive=$_isActive');
    if (_isActive) {
      _d('WhisperSTT.startSession() already active, returning');
      return;
    }
    _isActive = true;
    final sessionId = ++_sessionId;
    _cancelSpeechStartWatchdog();

    try {
      final dir = await getTemporaryDirectory();
      _recordingPath =
          '${dir.path}/memori_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      _recorder = AudioRecorder();

      _d('WhisperSTT.startSession() starting recorder at $_recordingPath');
      await _recorder!.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: _sampleRate,
          numChannels: 1,
          bitRate: _bitRate,
        ),
        path: _recordingPath!,
      );

      _d('WhisperSTT.startSession() recording STARTED');
      BatasphLogger.log('[STT] Recording started: $_recordingPath');

      // Monitor amplitude for silence detection
      final silenceSeconds = AppConfig.voiceSilenceSeconds;
      final silenceDelay = resolveEndOfSpeechDelay(silenceSeconds);
      final silenceWindowSamples = resolveSilenceWindowSamples(silenceSeconds);
      _turnDetector = WhisperTurnDetector(
        speechThresholdDb: _silenceThresholdDb,
        silenceWindowSamples: silenceWindowSamples,
      );
      _d(
        'WhisperSTT.startSession() silenceThreshold=${_silenceThresholdDb}dB '
        'configuredSilence=${silenceSeconds}s '
        'effectiveSilence=${silenceDelay.inMilliseconds}ms '
        'samples=$silenceWindowSamples',
      );

      _amplitudeSubscription = _recorder!
          .onAmplitudeChanged(_amplitudeInterval)
          .listen((amp) {
            final hadDetectedSpeech = _turnDetector!.hasDetectedSpeech;
            final action = _turnDetector!.observe(amp.current);
            final hasDetectedSpeech = _turnDetector!.hasDetectedSpeech;

            if (!hadDetectedSpeech && hasDetectedSpeech) {
              _cancelSpeechStartWatchdog();
              _d(
                'WhisperSTT [AMP] first speech detected, startup watchdog cleared',
              );
            }

            if (amp.current > _silenceThresholdDb && hasDetectedSpeech) {
              _d(
                'WhisperSTT [AMP] speech detected (${amp.current.toStringAsFixed(1)}dB)',
              );
            }

            if (action == WhisperTurnAction.stopForEndOfSpeech && _isActive) {
              _d(
                'WhisperSTT [AMP] END OF SPEECH reached '
                '(${silenceDelay.inMilliseconds}ms), stopping',
              );
              BatasphLogger.log('[STT] End of speech detected, stopping');
              _stopAndTranscribe();
            }
          });
      _armSpeechStartWatchdog(sessionId);
      _armMaxRecordingTimer(sessionId);
      _d('WhisperSTT.startSession() amplitude monitoring started');
    } catch (e) {
      _d('WhisperSTT.startSession() FAILED: $e');
      BatasphLogger.error('[STT] Failed to start session: $e');
      onError?.call('Failed to start recording: $e');
      _isActive = false;
      await _cleanup();
    }
  }

  @override
  Future<void> stopSession() async {
    _d('WhisperSTT.stopSession() called | isActive=$_isActive');
    if (!_isActive) return;
    BatasphLogger.log('[STT] stopSession() called');
    await _stopAndTranscribe();
    _d('WhisperSTT.stopSession() done');
  }

  @override
  Future<void> cancelSession() async {
    _d('WhisperSTT.cancelSession() called | isActive=$_isActive');
    BatasphLogger.log('[STT] cancelSession() called');
    _isActive = false;
    await _cleanup();
    _d('WhisperSTT.cancelSession() done');
  }

  Future<void> _stopAndTranscribe() async {
    _d(
      'WhisperSTT._stopAndTranscribe() called | isActive=$_isActive sessionId=$_sessionId',
    );
    if (!_isActive) {
      _d('WhisperSTT._stopAndTranscribe() not active, returning');
      return;
    }
    _isActive = false;
    final capturedSessionId = _sessionId;
    _cancelSpeechStartWatchdog();
    _cancelMaxRecordingTimer();

    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    _turnDetector?.reset();
    _turnDetector = null;

    String? filePath;
    try {
      _d('WhisperSTT._stopAndTranscribe() stopping recorder');
      filePath = await _recorder?.stop();
      _d(
        'WhisperSTT._stopAndTranscribe() recorder stopped, filePath=$filePath',
      );
    } catch (e) {
      _d('WhisperSTT._stopAndTranscribe() recorder stop FAILED: $e');
      BatasphLogger.error('[STT] Failed to stop recorder: $e');
    }

    _recorder?.dispose();
    _recorder = null;

    // Stale session — service was disposed/restarted while we were stopping.
    if (capturedSessionId != _sessionId) {
      _d(
        'WhisperSTT._stopAndTranscribe() STALE session ($capturedSessionId != $_sessionId), dropping',
      );
      if (filePath != null) _deleteFile(filePath);
      return;
    }

    if (filePath == null || filePath.isEmpty) {
      _d(
        'WhisperSTT._stopAndTranscribe() NO file path, calling onResult empty',
      );
      onResult?.call('', true);
      return;
    }

    final file = File(filePath);
    final exists = file.existsSync();
    final size = exists ? file.lengthSync() : 0;
    _d('WhisperSTT._stopAndTranscribe() file exists=$exists size=$size bytes');

    if (!exists || size < 1000) {
      _d(
        'WhisperSTT._stopAndTranscribe() file too small ($size bytes), returning empty',
      );
      BatasphLogger.log('[STT] Audio file too small or missing, skipping');
      onResult?.call('', true);
      _deleteFile(filePath);
      return;
    }

    // Signal the controller to transition to "processing" before the HTTP call.
    _d('WhisperSTT._stopAndTranscribe() firing onTranscribing callback');
    onTranscribing?.call();

    _d('WhisperSTT._stopAndTranscribe() sending $size bytes to /transcribe');
    BatasphLogger.log('[STT] Sending ${file.lengthSync()} bytes to Whisper');

    try {
      final languages = MySharedPref.getSpeechLanguages();
      final formData = dio.FormData.fromMap({
        'audio': await dio.MultipartFile.fromFile(
          filePath,
          filename: filePath.split('/').last,
        ),
        'languages': jsonEncode(languages),
      });

      _d(
        'WhisperSTT._stopAndTranscribe() POST /transcribe languages=$languages',
      );
      final response = await ApiClient().client.post(
        '/transcribe',
        data: formData,
        options: dio.Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      // Stale check after the HTTP call returns.
      if (capturedSessionId != _sessionId) {
        _d(
          'WhisperSTT._stopAndTranscribe() STALE after HTTP ($capturedSessionId != $_sessionId), dropping',
        );
        return;
      }

      final text = response.data['text'] as String?;
      _d('WhisperSTT._stopAndTranscribe() response text="${text ?? '<null>'}');

      if (text != null && text.trim().isNotEmpty) {
        _d(
          'WhisperSTT._stopAndTranscribe() → onResult("${text.trim()}", true)',
        );
        BatasphLogger.log('[STT] Transcript: ${text.trim()}');
        onResult?.call(text.trim(), true);
      } else {
        _d('WhisperSTT._stopAndTranscribe() → onResult("", true) (empty)');
        BatasphLogger.log('[STT] Empty transcript returned');
        onResult?.call('', true);
      }
    } catch (e) {
      if (capturedSessionId != _sessionId) {
        _d(
          'WhisperSTT._stopAndTranscribe() STALE after error ($capturedSessionId != $_sessionId), dropping',
        );
        return;
      }
      _d('WhisperSTT._stopAndTranscribe() transcription FAILED: $e');
      BatasphLogger.error('[STT] Transcription failed: $e');
      onError?.call('Transcription failed');
    } finally {
      _deleteFile(filePath);
    }
  }

  Future<void> _cleanup() async {
    _d('WhisperSTT._cleanup() START');
    _cancelSpeechStartWatchdog();
    _cancelMaxRecordingTimer();
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    _turnDetector?.reset();
    _turnDetector = null;

    try {
      await _recorder?.stop();
    } catch (e) {
      _d('WhisperSTT recorder.stop threw during teardown (ignored): $e');
    }
    _recorder?.dispose();
    _recorder = null;

    if (_recordingPath != null) {
      _deleteFile(_recordingPath!);
      _recordingPath = null;
    }
    _d('WhisperSTT._cleanup() DONE');
  }

  void _armSpeechStartWatchdog(int sessionId) {
    _cancelSpeechStartWatchdog();
    _speechStartWatchdog = Timer(_speechStartTimeout, () async {
      await _handleSpeechStartTimeout(sessionId);
    });
  }

  Future<void> _handleSpeechStartTimeout(int sessionId) async {
    if (!_isActive || sessionId != _sessionId) {
      return;
    }
    if (_turnDetector?.hasDetectedSpeech ?? false) {
      return;
    }

    _d('WhisperSTT speech-start watchdog fired: no speech detected');
    BatasphLogger.log('[STT] Speech-start watchdog fired');
    await cancelSession();
    onResult?.call('', true);
  }

  void _cancelSpeechStartWatchdog() {
    _speechStartWatchdog?.cancel();
    _speechStartWatchdog = null;
  }

  void _armMaxRecordingTimer(int sessionId) {
    _cancelMaxRecordingTimer();
    _maxRecordingTimer = Timer(_maxRecordingDuration, () {
      if (!_isActive || sessionId != _sessionId) return;
      _d(
        'WhisperSTT max recording timer fired (${_maxRecordingDuration.inSeconds}s), force-stopping',
      );
      BatasphLogger.log('[STT] Max recording duration reached, stopping');
      _stopAndTranscribe();
    });
  }

  void _cancelMaxRecordingTimer() {
    _maxRecordingTimer?.cancel();
    _maxRecordingTimer = null;
  }

  void _deleteFile(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    } catch (e) {
      _d('WhisperSTT could not delete temp file $path (ignored): $e');
    }
  }

  @override
  Future<void> dispose() async {
    _d('WhisperSTT.dispose() called');
    _isActive = false;
    await _cleanup();
    onResult = null;
    onError = null;
    onTranscribing = null;
    _d('WhisperSTT.dispose() done');
  }
}
