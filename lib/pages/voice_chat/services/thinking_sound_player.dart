import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

import 'package:batasph_mobile/pages/voice_chat/services/helpers/pcm_wav_helper.dart';
import 'package:batasph_mobile/utils/logger_util.dart';

/// The soft loop that plays between the filler and the first reply audio so
/// the wait is never silent. Synthesized at runtime like the call tones in
/// `VoiceCallAudioService` — no asset, no network, the same for every voice.
///
/// start() and stop() may overlap (the first reply chunk can land while the
/// player is still starting), so stop() always waits for an in-flight start
/// before stopping: the loop can never begin after it was told to stop.
class ThinkingSoundPlayer {
  static const double volume = 0.3;

  AudioPlayer? _player;
  Future<AudioPlayer>? _ready;
  bool _playing = false;
  Future<void>? _starting;

  bool get isPlaying => _playing;

  /// Creates the player and loads the loop so the first start() does not
  /// pay the setup right when the loop should begin.
  Future<void> warmUp() async {
    try {
      await _readyPlayer();
    } catch (error) {
      BatasphLogger.debug('[Voice] Thinking loop warm-up failed: $error');
    }
  }

  Future<AudioPlayer> _readyPlayer() {
    return _ready ??=
        () async {
          // Deliberately no setAudioContext: on Android audioplayers applies part
          // of a player's AudioContext globally, and doing so here lost the
          // microphone mid-session in Memori's device tests.
          final player = AudioPlayer();
          await player.setReleaseMode(ReleaseMode.loop);
          await player.setVolume(volume);
          await player.setSource(
            BytesSource(_buildThinkingLoop(), mimeType: 'audio/wav'),
          );
          _player = player;
          return player;
        }().catchError((Object error) {
          _ready = null; // let the next call try again
          throw error;
        });
  }

  Future<void> start() async {
    if (_playing) return;
    _playing = true;
    _starting = _begin();
    await _starting;
  }

  Future<void> _begin() async {
    try {
      final player = await _readyPlayer();
      if (!_playing) return; // stopped while we were setting up
      await player.setVolume(volume);
      await player.resume();
      BatasphLogger.debug('[Voice] Thinking loop started');
    } catch (error, stackTrace) {
      // Ambience only; the reply still plays without it.
      _playing = false;
      BatasphLogger.error(
        '[Voice] Thinking loop failed to start',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Fades out over ~150 ms so the reply does not start on a hard cut.
  Future<void> stop() async {
    final wasPlaying = _playing;
    _playing = false;
    final starting = _starting;
    if (!wasPlaying && starting == null) return;
    _starting = null;
    try {
      await starting;
    } catch (_) {}
    final player = _player;
    if (player == null) return;
    try {
      if (wasPlaying) {
        for (final level in [0.2, 0.1, 0.0]) {
          await player.setVolume(level);
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      }
      // pause, not stop: keeps the source loaded so the next start is instant.
      await player.pause();
      await player.seek(Duration.zero);
      BatasphLogger.debug('[Voice] Thinking loop stopped');
    } catch (error) {
      BatasphLogger.debug('[Voice] Thinking loop stop error ignored: $error');
    }
  }

  Future<void> dispose() async {
    await stop();
    try {
      await _player?.dispose();
    } catch (_) {}
    _player = null;
    _ready = null;
  }

  /// A gentle two-note pulse every 1.4 s, quiet enough to sit under speech.
  static Uint8List _buildThinkingLoop() {
    const sampleRate = 16000;
    const durationMs = 1400;
    final totalSamples = (sampleRate * durationMs / 1000).round();
    final samples = Iterable<double>.generate(totalSamples, (index) {
      final t = index / sampleRate;
      return _pulse(t, start: 0.0, length: 0.22, frequency: 520) +
          _pulse(t, start: 0.34, length: 0.22, frequency: 660);
    });
    return wrapPcmAsWav(sampleRate: sampleRate, pcmData: encodePcm16(samples));
  }

  static double _pulse(
    double t, {
    required double start,
    required double length,
    required double frequency,
  }) {
    if (t < start || t > start + length) {
      return 0;
    }
    final progress = ((t - start) / length).clamp(0.0, 1.0);
    final envelope = math.sin(progress * math.pi);
    return math.sin(2 * math.pi * frequency * t) * 0.18 * envelope;
  }
}
