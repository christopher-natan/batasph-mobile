import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:batasph_mobile/pages/voice_chat/services/helpers/pcm_wav_helper.dart';

/// The phone-line sounds around a call, synthesized at runtime: the
/// ringback the caller hears, the clunk of Luna lifting an old handset off
/// its cradle, and the "call dropped" beeps when it ends.
class VoiceCallAudioService {
  static const int _sampleRate = 16000;

  /// Classic ringback: 440 Hz + 480 Hz, two-second rings.
  static const List<double> _ringFrequencies = [440, 480];
  static const double _ringSeconds = 2.0;
  static const double _ringGapSeconds = 2.5;

  /// Luna picks up shortly after the second ring.
  static const int _rings = 2;
  static const double _beforePickUpSeconds = 0.35;
  static const double _afterPickUpSeconds = 0.3;

  /// Call dropped: three short 480 Hz + 620 Hz beeps.
  static const List<double> _dropFrequencies = [480, 620];
  static const int _dropBeeps = 3;
  static const double _dropBeepSeconds = 0.18;
  static const double _dropGapSeconds = 0.14;

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

  /// Rings [_rings] times and picks up, then completes: Luna is on the line.
  /// Completes early if [stop] is called.
  Future<void> playRingback() => _playOnce(_buildRingback(), volume: 0.7);

  Future<void> playCallDroppedTone() =>
      _playOnce(_buildCallDropped(), volume: 0.8);

  Future<void> _playOnce(Uint8List wav, {required double volume}) async {
    await stop();
    final player = _getPlayer();
    await player.setReleaseMode(ReleaseMode.stop);
    final completer = Completer<void>();
    _playCompleter = completer;
    await player.play(BytesSource(wav, mimeType: 'audio/wav'), volume: volume);
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

  Uint8List _buildRingback() {
    final pcm = BytesBuilder();
    for (var ring = 0; ring < _rings; ring++) {
      _addTone(pcm, _ringFrequencies, _ringSeconds, amplitude: 0.3);
      _addSilence(
        pcm,
        ring < _rings - 1 ? _ringGapSeconds : _beforePickUpSeconds,
      );
    }
    _addPickUp(pcm);
    _addSilence(pcm, _afterPickUpSeconds);
    return wrapPcmAsWav(sampleRate: _sampleRate, pcmData: pcm.takeBytes());
  }

  Uint8List _buildCallDropped() {
    final pcm = BytesBuilder();
    for (var beep = 0; beep < _dropBeeps; beep++) {
      _addTone(pcm, _dropFrequencies, _dropBeepSeconds, amplitude: 0.32);
      _addSilence(pcm, _dropGapSeconds);
    }
    return wrapPcmAsWav(sampleRate: _sampleRate, pcmData: pcm.takeBytes());
  }

  /// A steady dual tone with 15 ms fades, so it starts and stops without
  /// clicks.
  static void _addTone(
    BytesBuilder pcm,
    List<double> frequencies,
    double seconds, {
    required double amplitude,
  }) {
    final total = (_sampleRate * seconds).round();
    final fade = (_sampleRate * 0.015).round();
    for (var i = 0; i < total; i++) {
      final t = i / _sampleRate;
      var sample = 0.0;
      for (final frequency in frequencies) {
        sample += math.sin(2 * math.pi * frequency * t);
      }
      sample /= frequencies.length;
      final envelope = math.min(1.0, math.min(i, total - 1 - i) / fade);
      _addSample(pcm, sample * amplitude * envelope);
    }
  }

  /// An old handset lifted off its cradle: the hook switch's click over a
  /// low body thump, then a softer click as the handset settles.
  static void _addPickUp(BytesBuilder pcm) {
    final noise = math.Random(4136); // fixed seed: the same clunk every call
    final total = (_sampleRate * 0.16).round();
    final settleAt = (_sampleRate * 0.085).round();
    for (var i = 0; i < total; i++) {
      final t = i / _sampleRate;
      final thump = math.sin(2 * math.pi * 95 * t) * math.exp(-t / 0.03) * 0.55;
      final click = (noise.nextDouble() * 2 - 1) * math.exp(-t / 0.004) * 0.6;
      var settle = 0.0;
      if (i >= settleAt) {
        final ts = (i - settleAt) / _sampleRate;
        settle =
            (noise.nextDouble() * 2 - 1) * math.exp(-ts / 0.003) * 0.25 +
            math.sin(2 * math.pi * 160 * ts) * math.exp(-ts / 0.015) * 0.2;
      }
      _addSample(pcm, (thump + click + settle).clamp(-1.0, 1.0));
    }
  }

  static void _addSilence(BytesBuilder pcm, double seconds) {
    pcm.add(Uint8List((_sampleRate * seconds).round() * 2));
  }

  static void _addSample(BytesBuilder pcm, double sample) {
    final value = (sample * 32767).round().clamp(-32768, 32767);
    pcm
      ..addByte(value & 0xFF)
      ..addByte((value >> 8) & 0xFF);
  }
}
