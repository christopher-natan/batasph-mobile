import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'package:batasph_mobile/utils/logger_util.dart';

/// Measures how loud the microphone is while the assistant is speaking,
/// against how loud it is while nobody is. Ported from Memori.
///
/// This is the one number that decides whether barge-in is possible at all.
/// If the platform echo canceller is doing its job, the two are close: our own
/// voice never reaches the capture path, so the microphone can stay open while
/// we speak. If the assistant's own output leaks through, the speaking figure
/// sits well above the quiet one and any voice activity detector — ours or
/// OpenAI's — will fire on the assistant itself.
///
/// It runs in every mode, including `VoiceBargeInMode.off`, because the
/// recorder keeps running while muted: the frames are simply not sent. So the
/// measurement costs no audio minutes and does not touch the audio route.
///
/// Two scopes are kept at once. The **turn** scope is what shows variation —
/// one reply spoken at full volume next to the ear reads very differently
/// from one on a desk — and the **session** scope is the headline figure.
class VoiceEchoProbe {
  /// Quiet enough that the sample is silence rather than signal.
  static const double silenceFloorDbfs = -100;

  final _turn = _Scope();
  final _session = _Scope();

  /// RMS level of one PCM16 mono frame, in dBFS (0 = full scale).
  ///
  /// Returns [silenceFloorDbfs] for digital silence and for a frame too short
  /// to hold a sample, so the caller never has to handle -infinity.
  static double rmsDbfs(Uint8List pcm16) {
    final sampleCount = pcm16.lengthInBytes ~/ 2;
    if (sampleCount == 0) return silenceFloorDbfs;

    final view = ByteData.view(
      pcm16.buffer,
      pcm16.offsetInBytes,
      sampleCount * 2,
    );
    var sumOfSquares = 0.0;
    for (var i = 0; i < sampleCount; i++) {
      final sample = view.getInt16(i * 2, Endian.little) / 32768.0;
      sumOfSquares += sample * sample;
    }

    final rms = math.sqrt(sumOfSquares / sampleCount);
    if (rms <= 0) return silenceFloorDbfs;
    return math.max(silenceFloorDbfs, 20 * (math.log(rms) / math.ln10));
  }

  /// Records one frame. [assistantSpeaking] is the caller's view of whether
  /// our own audio was playing when this frame was captured.
  void addFrame(Uint8List pcm16, {required bool assistantSpeaking}) {
    addLevel(rmsDbfs(pcm16), assistantSpeaking: assistantSpeaking);
  }

  /// Same, when the level has already been computed.
  void addLevel(double dbfs, {required bool assistantSpeaking}) {
    _turn.add(dbfs, assistantSpeaking: assistantSpeaking);
    _session.add(dbfs, assistantSpeaking: assistantSpeaking);
  }

  bool get hasSamples => _session.hasSamples;

  /// How far the microphone rises above its own quiet floor while we speak,
  /// across the whole conversation.
  ///
  /// Near zero means the echo canceller is removing our voice. A large
  /// positive number is the assistant leaking into its own microphone, and it
  /// is the reason to stop before opening the microphone any further.
  /// Null until both sides have been measured.
  double? get echoLeakDb => _session.leakDb;

  /// The same figure for the turn in progress. Null until both sides of this
  /// turn have been measured.
  double? get turnEchoLeakDb => _turn.leakDb;

  /// Writes the figures for one assistant turn, then starts the next turn.
  ///
  /// Called per turn on purpose: a conversation-level average hides the case
  /// where one loud reply leaks badly and three quiet ones do not.
  void logTurn(String label) {
    if (_turn.hasSamples) {
      BatasphLogger.log('[BARGE] echo turn $label | ${_turn.describe()}');
    }
    _turn.reset();
  }

  /// Writes the headline figure for the conversation.
  void logSession(String label) {
    if (!_session.hasSamples) return;
    BatasphLogger.log('[BARGE] echo TOTAL $label | ${_session.describe()}');
  }

  void reset() {
    _turn.reset();
    _session.reset();
  }
}

/// One speaking/quiet pair over some window.
class _Scope {
  final _speaking = _LevelBucket();
  final _quiet = _LevelBucket();

  bool get hasSamples => _speaking.count > 0 || _quiet.count > 0;

  double? get leakDb {
    if (_speaking.count == 0 || _quiet.count == 0) return null;
    return _speaking.meanDbfs - _quiet.meanDbfs;
  }

  void add(double dbfs, {required bool assistantSpeaking}) {
    (assistantSpeaking ? _speaking : _quiet).add(dbfs);
  }

  String describe() {
    final leak = leakDb;
    return 'speaking ${_speaking.describe()} | '
        'quiet ${_quiet.describe()} | '
        'leak=${leak == null ? 'n/a' : '${leak.toStringAsFixed(1)}dB'}';
  }

  void reset() {
    _speaking.reset();
    _quiet.reset();
  }
}

class _LevelBucket {
  int count = 0;
  double _sum = 0;
  double _peak = VoiceEchoProbe.silenceFloorDbfs;
  double _min = 0;

  double get meanDbfs =>
      count == 0 ? VoiceEchoProbe.silenceFloorDbfs : _sum / count;

  void add(double dbfs) {
    count++;
    _sum += dbfs;
    if (dbfs > _peak) _peak = dbfs;
    if (count == 1 || dbfs < _min) _min = dbfs;
  }

  String describe() => count == 0
      ? 'none'
      : 'mean=${meanDbfs.toStringAsFixed(1)}dBFS '
            'peak=${_peak.toStringAsFixed(1)}dBFS n=$count';

  void reset() {
    count = 0;
    _sum = 0;
    _peak = VoiceEchoProbe.silenceFloorDbfs;
    _min = 0;
  }
}
