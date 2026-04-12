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

  bool _isActive = false;
  int _sessionId = 0;

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
    _cancelSpeechStartWatchdog();

    try {
      final hasPermission = await AudioRecorder().hasPermission();
      if (!hasPermission) {
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

      _amplitudeSubscription = _recorder!
          .onAmplitudeChanged(_amplitudeInterval)
          .listen((amplitude) {
            final hadDetectedSpeech = _turnDetector!.hasDetectedSpeech;
            final action = _turnDetector!.observe(amplitude.current);
            final hasDetectedSpeech = _turnDetector!.hasDetectedSpeech;

            if (!hadDetectedSpeech && hasDetectedSpeech) {
              _cancelSpeechStartWatchdog();
            }

            if (action == WhisperTurnAction.stopForEndOfSpeech && _isActive) {
              _stopAndTranscribe();
            }
          });

      _armSpeechStartWatchdog(sessionId);
      _armMaxRecordingTimer(sessionId);
    } catch (error) {
      BatasphLogger.error('Failed to start Whisper STT session: $error');
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
    } catch (error) {
      BatasphLogger.error('Failed to stop Whisper STT recorder: $error');
    }

    _recorder?.dispose();
    _recorder = null;

    if (capturedSessionId != _sessionId) {
      if (filePath != null) {
        _deleteFile(filePath);
      }
      return;
    }

    if (filePath == null || filePath.isEmpty) {
      onResult?.call('', true);
      return;
    }

    final file = File(filePath);
    final exists = file.existsSync();
    final size = exists ? file.lengthSync() : 0;
    if (!exists || size < 1000) {
      onResult?.call('', true);
      _deleteFile(filePath);
      return;
    }

    onTranscribing?.call();

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
        return;
      }

      final text = response.data['text'] as String?;
      if (text != null && text.trim().isNotEmpty) {
        onResult?.call(text.trim(), true);
      } else {
        onResult?.call('', true);
      }
    } catch (error) {
      if (capturedSessionId != _sessionId) {
        return;
      }
      BatasphLogger.error('Whisper transcription failed: $error');
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
  }
}
