import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'dart:convert';

import 'package:batasph_mobile/data/local/my_shared_pref.dart';
import 'package:batasph_mobile/data/remote/api_client.dart';
import 'package:batasph_mobile/pages/voice_chat/services/stt_service.dart';
import 'package:batasph_mobile/pages/voice_chat/services/whisper_turn_detector.dart';
import 'package:batasph_mobile/utils/logger_util.dart';

class WhisperSttService extends SttService {
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

  bool _isActive = false;
  int _sessionId = 0;
  Stopwatch? _sessionStopwatch;

  @override
  bool get isActive => _isActive;

  @override
  Future<void> warmUp() async {}

  @override
  Future<void> startSession() async {
    if (_isActive) {
      return;
    }

    _isActive = true;
    final sessionId = ++_sessionId;
    _sessionStopwatch = Stopwatch()..start();
    _cancelSpeechStartWatchdog();

    try {
      final hasPermission = await AudioRecorder().hasPermission();
      if (!hasPermission) {
        BatasphLogger.warning(
          '[STT] Microphone permission denied | session=$sessionId',
        );
        throw StateError('Microphone permission was denied');
      }

      final dir = await getTemporaryDirectory();
      _recordingPath =
          '${dir.path}/batasph_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      _recorder = AudioRecorder();
      await _recorder!.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: _sampleRate,
          numChannels: 1,
          bitRate: _bitRate,
        ),
        path: _recordingPath!,
      );

      final silenceSeconds = MySharedPref.getVoiceSilenceSeconds();
      final silenceWindowSamples = resolveSilenceWindowSamples(silenceSeconds);
      _turnDetector = WhisperTurnDetector(
        speechThresholdDb: _silenceThresholdDb,
        silenceWindowSamples: silenceWindowSamples,
      );
      BatasphLogger.log(
        '[STT] Recording started | session=$sessionId'
        ' | silence=${silenceSeconds}s -> window=$silenceWindowSamples samples'
        ' | threshold=${_silenceThresholdDb}dB',
      );

      _amplitudeSubscription = _recorder!
          .onAmplitudeChanged(_amplitudeInterval)
          .listen((amplitude) {
            final hadDetectedSpeech = _turnDetector!.hasDetectedSpeech;
            final action = _turnDetector!.observe(amplitude.current);
            final hasDetectedSpeech = _turnDetector!.hasDetectedSpeech;

            if (!hadDetectedSpeech && hasDetectedSpeech) {
              BatasphLogger.log(
                '[STT] Speech detected | session=$sessionId'
                ' | at=${_sessionStopwatch?.elapsedMilliseconds}ms'
                ' | ${amplitude.current.toStringAsFixed(1)}dB',
              );
              _cancelSpeechStartWatchdog();
              onSpeechStarted?.call();
            }

            if (action == WhisperTurnAction.stopForEndOfSpeech && _isActive) {
              BatasphLogger.log(
                '[STT] End of speech | session=$sessionId'
                ' | at=${_sessionStopwatch?.elapsedMilliseconds}ms',
              );
              _stopAndTranscribe();
            }
          });

      _armSpeechStartWatchdog(sessionId);
      _armMaxRecordingTimer(sessionId);
    } catch (error, stackTrace) {
      BatasphLogger.error(
        '[STT] Failed to start session | session=$sessionId',
        error: error,
        stackTrace: stackTrace,
      );
      onError?.call('Failed to start recording');
      _isActive = false;
      await _cleanup();
    }
  }

  @override
  Future<void> stopSession() async {
    if (!_isActive) {
      return;
    }
    await _stopAndTranscribe();
  }

  @override
  Future<void> cancelSession() async {
    if (_isActive) {
      BatasphLogger.log(
        '[STT] Session cancelled | session=$_sessionId'
        ' | at=${_sessionStopwatch?.elapsedMilliseconds}ms',
      );
    }
    _isActive = false;
    await _cleanup();
  }

  Future<void> _stopAndTranscribe() async {
    if (!_isActive) {
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
      filePath = await _recorder?.stop();
    } catch (error, stackTrace) {
      BatasphLogger.error(
        '[STT] Failed to stop recorder | session=$capturedSessionId',
        error: error,
        stackTrace: stackTrace,
      );
    }

    _recorder?.dispose();
    _recorder = null;

    if (capturedSessionId != _sessionId) {
      BatasphLogger.log(
        '[STT] Recording discarded, session superseded'
        ' | session=$capturedSessionId | current=$_sessionId',
      );
      if (filePath != null) {
        _deleteFile(filePath);
      }
      return;
    }

    if (filePath == null || filePath.isEmpty) {
      BatasphLogger.warning(
        '[STT] Recorder returned no file | session=$capturedSessionId',
      );
      onResult?.call('', true);
      return;
    }

    final file = File(filePath);
    final exists = file.existsSync();
    final size = exists ? file.lengthSync() : 0;
    if (!exists || size < 1000) {
      BatasphLogger.log(
        '[STT] Recording too small, treated as silence'
        ' | session=$capturedSessionId | exists=$exists | bytes=$size',
      );
      onResult?.call('', true);
      _deleteFile(filePath);
      return;
    }

    BatasphLogger.log(
      '[STT] Uploading | session=$capturedSessionId | bytes=$size'
      ' | recorded=${_sessionStopwatch?.elapsedMilliseconds}ms',
    );
    onTranscribing?.call();
    final uploadStopwatch = Stopwatch()..start();

    try {
      final languages = MySharedPref.getSpeechLanguages();
      final formData = dio.FormData.fromMap({
        'audio': await dio.MultipartFile.fromFile(
          filePath,
          filename: filePath.split('/').last,
        ),
        'languages': jsonEncode(languages),
      });

      final response = await ApiClient().client.post(
        '/transcribe',
        data: formData,
        options: dio.Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      if (capturedSessionId != _sessionId) {
        BatasphLogger.log(
          '[STT] Transcript discarded, session superseded'
          ' | session=$capturedSessionId | current=$_sessionId',
        );
        return;
      }

      final text = response.data['text'] as String?;
      BatasphLogger.log(
        '[STT] Transcribed | session=$capturedSessionId'
        ' | ${uploadStopwatch.elapsedMilliseconds}ms'
        ' | chars=${text?.trim().length ?? 0}',
      );
      if (text != null && text.trim().isNotEmpty) {
        onResult?.call(text.trim(), true);
      } else {
        onResult?.call('', true);
      }
    } catch (error, stackTrace) {
      if (capturedSessionId != _sessionId) {
        return;
      }
      BatasphLogger.error(
        '[STT] Transcription failed | session=$capturedSessionId'
        ' | ${uploadStopwatch.elapsedMilliseconds}ms',
        error: error,
        stackTrace: stackTrace,
      );
      onError?.call('Transcription failed');
    } finally {
      _deleteFile(filePath);
    }
  }

  Future<void> _cleanup() async {
    _cancelSpeechStartWatchdog();
    _cancelMaxRecordingTimer();
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    _turnDetector?.reset();
    _turnDetector = null;

    try {
      await _recorder?.stop();
    } catch (_) {}
    _recorder?.dispose();
    _recorder = null;

    if (_recordingPath != null) {
      _deleteFile(_recordingPath!);
      _recordingPath = null;
    }
  }

  void _armSpeechStartWatchdog(int sessionId) {
    _cancelSpeechStartWatchdog();
    _speechStartWatchdog = Timer(_speechStartTimeout, () async {
      if (!_isActive || sessionId != _sessionId) {
        return;
      }
      if (_turnDetector?.hasDetectedSpeech ?? false) {
        return;
      }

      BatasphLogger.log(
        '[STT] No speech within ${_speechStartTimeout.inSeconds}s'
        ' | session=$sessionId',
      );
      await cancelSession();
      onResult?.call('', true);
    });
  }

  void _cancelSpeechStartWatchdog() {
    _speechStartWatchdog?.cancel();
    _speechStartWatchdog = null;
  }

  void _armMaxRecordingTimer(int sessionId) {
    _cancelMaxRecordingTimer();
    _maxRecordingTimer = Timer(_maxRecordingDuration, () {
      if (!_isActive || sessionId != _sessionId) {
        return;
      }
      BatasphLogger.log(
        '[STT] Max recording ${_maxRecordingDuration.inSeconds}s reached'
        ' | session=$sessionId',
      );
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
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (_) {}
  }

  @override
  Future<void> dispose() async {
    _isActive = false;
    await _cleanup();
    onResult = null;
    onError = null;
    onTranscribing = null;
    onSpeechStarted = null;
    onIdle = null;
  }
}
