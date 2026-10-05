import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:batasph_mobile/pages/voice_chat/services/helpers/pcm_wav_helper.dart';

class VoiceCallAudioService {
  AudioPlayer? _player;
  Completer<void>? _playCompleter;

  AudioPlayer _getPlayer() {
    if (_player == null) {
      _player = AudioPlayer();
      _player!.onPlayerComplete.listen((_) {
        _completePlayback();
      });
    }
    return _player!;
  }

  Future<void> playRingingLoop() async {
    await stop();
    final player = _getPlayer();
    await player.setReleaseMode(ReleaseMode.loop);
    final completer = Completer<void>();
    _playCompleter = completer;
    await player.play(
      BytesSource(_buildRingtoneLoop(), mimeType: 'audio/wav'),
      volume: 0.82,
    );
  }

  Future<void> playEndCallTone() async {
    await stop();
    final player = _getPlayer();
    await player.setReleaseMode(ReleaseMode.stop);

    final completer = Completer<void>();
    _playCompleter = completer;
    await player.play(
      BytesSource(_buildEndCallTone(), mimeType: 'audio/wav'),
      volume: 0.9,
    );
    await completer.future;
  }

  Future<void> stop() async {
    try {
      await _player?.stop();
    } catch (_) {}
    _completePlayback();
  }

  Future<void> dispose() async {
    await stop();
    try {
      await _player?.dispose();
    } catch (_) {}
    _player = null;
  }

  void _completePlayback() {
    final completer = _playCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
    _playCompleter = null;
  }

  Uint8List _buildEndCallTone() {
    const sampleRate = 16000;
    const durationMs = 260;
    final totalSamples = (sampleRate * durationMs / 1000).round();
    final pcmBytes = BytesBuilder();

    for (var index = 0; index < totalSamples; index++) {
      final progress = index / totalSamples;
      final frequency = 720 - (progress * 260);
      final envelope = math.sin(progress * math.pi).clamp(0.0, 1.0);
      final sample =
          math.sin(2 * math.pi * frequency * (index / sampleRate)) *
          0.38 *
          envelope;
      final value = (sample * 32767).round().clamp(-32768, 32767);
      pcmBytes.addByte(value & 0xFF);
      pcmBytes.addByte((value >> 8) & 0xFF);
    }

    return wrapPcmAsWav(sampleRate: sampleRate, pcmData: pcmBytes.takeBytes());
  }

  Uint8List _buildRingtoneLoop() {
    const sampleRate = 16000;
    const durationMs = 1500;
    final totalSamples = (sampleRate * durationMs / 1000).round();
    final pcmBytes = BytesBuilder();

    for (var index = 0; index < totalSamples; index++) {
      final timeSeconds = index / sampleRate;
      final sample = _ringingSampleAt(timeSeconds);
      final value = (sample * 32767).round().clamp(-32768, 32767);
      pcmBytes.addByte(value & 0xFF);
      pcmBytes.addByte((value >> 8) & 0xFF);
    }

    return wrapPcmAsWav(sampleRate: sampleRate, pcmData: pcmBytes.takeBytes());
  }

  double _ringingSampleAt(double timeSeconds) {
    const ringWindowSeconds = 1.1;
    if (timeSeconds >= ringWindowSeconds) {
      return 0;
    }

    final pulse =
        timeSeconds < 0.32 || (timeSeconds >= 0.46 && timeSeconds < 0.78);
    if (!pulse) {
      return 0;
    }

    final pulseStart = timeSeconds < 0.32 ? 0.0 : 0.46;
    final pulseDuration = timeSeconds < 0.32 ? 0.32 : 0.32;
    final pulseProgress = ((timeSeconds - pulseStart) / pulseDuration).clamp(
      0.0,
      1.0,
    );
    final envelope = math.sin(pulseProgress * math.pi).clamp(0.0, 1.0);
    final toneA = math.sin(2 * math.pi * 480 * timeSeconds);
    final toneB = math.sin(2 * math.pi * 620 * timeSeconds);
    return (toneA * 0.58 + toneB * 0.42) * 0.34 * envelope;
  }
}
