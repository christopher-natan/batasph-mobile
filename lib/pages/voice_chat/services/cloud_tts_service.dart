import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart' as dio;
import 'package:batasph_mobile/data/local/my_shared_pref.dart';
import 'package:batasph_mobile/data/remote/api_client.dart';
import 'package:batasph_mobile/pages/voice_chat/services/tts_service.dart';
import 'package:batasph_mobile/utils/logger_util.dart';

class CloudTtsService implements TtsService {
  AudioPlayer? _player;
  Completer<void>? _playCompleter;
  bool _stopped = false;

  AudioPlayer _getPlayer() {
    if (_player == null) {
      _player = AudioPlayer();
      _player!.onPlayerComplete.listen((_) {
        _completePlay();
      });
    }
    return _player!;
  }

  @override
  Future<Uint8List> synthesize(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw StateError('Cannot synthesize empty text');
    }

    final voice = MySharedPref.getSelectedVoice();
    final stopwatch = Stopwatch()..start();
    BatasphLogger.log(
      '[TTS] Synthesize | voice=$voice | chars=${trimmed.length}',
    );
    final response = await ApiClient().client.post(
      '/tts/synthesize',
      data: {'text': trimmed, 'voice': voice},
      options: dio.Options(
        responseType: dio.ResponseType.bytes,
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    final audioBytes = response.data as Uint8List;
    if (audioBytes.isEmpty) {
      BatasphLogger.error(
        '[TTS] Empty audio from backend | voice=$voice'
        ' | ${stopwatch.elapsedMilliseconds}ms',
      );
      throw StateError('Empty audio response from TTS backend');
    }

    BatasphLogger.log(
      '[TTS] Synthesized | ${stopwatch.elapsedMilliseconds}ms'
      ' | bytes=${audioBytes.length}',
    );
    return audioBytes;
  }

  @override
  Future<void> playAudio(Uint8List audioBytes) async {
    _stopped = false;
    final stopwatch = Stopwatch()..start();

    try {
      final completer = Completer<void>();
      _playCompleter = completer;

      BatasphLogger.debug('[TTS] Play | bytes=${audioBytes.length}');
      await _getPlayer().play(BytesSource(audioBytes, mimeType: 'audio/mpeg'));
      await completer.future;
      BatasphLogger.debug(
        '[TTS] Play ${_stopped ? 'stopped' : 'complete'}'
        ' | ${stopwatch.elapsedMilliseconds}ms',
      );
    } catch (error, stackTrace) {
      if (_stopped) {
        return;
      }
      BatasphLogger.error(
        '[TTS] Playback failed | ${stopwatch.elapsedMilliseconds}ms',
        error: error,
        stackTrace: stackTrace,
      );
      _completePlay();
      rethrow;
    }
  }

  @override
  Future<void> speak(String text) async {
    _stopped = false;
    final audioBytes = await synthesize(text);
    if (_stopped) {
      return;
    }
    await playAudio(audioBytes);
  }

  @override
  Future<void> stop() async {
    _stopped = true;

    try {
      if (_player != null &&
          _playCompleter != null &&
          !_playCompleter!.isCompleted) {
        BatasphLogger.debug('[TTS] Stop requested mid-playback, fading out');
        const steps = 3;
        const stepDuration = Duration(milliseconds: 50);
        for (var index = steps - 1; index >= 0; index--) {
          await _player!.setVolume(index / steps);
          await Future.delayed(stepDuration);
        }
      }
      await _player?.stop();
      await _player?.setVolume(1.0);
    } catch (_) {}

    _completePlay();
  }

  @override
  Future<void> dispose() async {
    await stop();
    try {
      await _player?.dispose();
    } catch (_) {}
    _player = null;
  }

  void _completePlay() {
    final completer = _playCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
    _playCompleter = null;
  }
}
