import 'dart:async';

import 'package:batasph_mobile/pages/voice_chat/services/voice_barge_in_mode.dart';

/// Decides whether speech heard while the assistant is talking is a real
/// interruption. Ported from Memori.
///
/// Two stages, because the two mistakes cost very differently. Ducking on the
/// first sound is cheap and reversible; stopping is not — get it wrong and
/// the answer is gone. So ducking is eager and stopping waits for evidence.
///
/// ```
/// speech heard ──► duck ──► words confirm it ──► stop
///                    └────► nothing in [falseAlarmWindow] ──► un-duck, carry on
/// ```
///
/// Evidence is words, not energy: the VAD fires on a television as readily
/// as on the user, so real words are what separate the two.
class BargeInDetector {
  BargeInDetector({
    required this.onDuck,
    required this.onConfirm,
    required this.onRelease,
    this.falseAlarmWindow = VoiceBargeIn.falseAlarmWindow,
    this.minWords = VoiceBargeIn.minWords,
  });

  /// Yield the floor: called the instant speech is heard.
  final void Function() onDuck;

  /// A real interruption, carrying the words that proved it.
  final void Function(String transcript) onConfirm;

  /// It was not speech after all — take the floor back.
  final void Function() onRelease;

  final Duration falseAlarmWindow;
  final int minWords;

  Timer? _falseAlarmTimer;
  bool _ducked = false;
  bool _confirmed = false;

  bool get isDucked => _ducked;
  bool get hasConfirmed => _confirmed;

  /// The VAD heard something while we were speaking.
  void onSpeechStarted() {
    if (_confirmed || _ducked) return;
    _ducked = true;
    onDuck();
    _falseAlarmTimer?.cancel();
    _falseAlarmTimer = Timer(falseAlarmWindow, _releaseAsFalseAlarm);
  }

  /// A transcript arrived for that speech — partial or final. [isEcho] comes
  /// from the caller, which knows what we are saying: residual echo is the
  /// assistant hearing itself and must never confirm.
  void onTranscript(String transcript, {required bool isEcho}) {
    if (_confirmed || isEcho) return;
    if (_meaningfulWords(transcript) < minWords) return;

    // Words arriving before the VAD's own speech_started still count: the
    // transcript is the stronger signal of the two.
    if (!_ducked) {
      _ducked = true;
      onDuck();
    }
    _confirmed = true;
    _falseAlarmTimer?.cancel();
    _falseAlarmTimer = null;
    onConfirm(transcript.trim());
  }

  /// Counts words that could carry an intention, ignoring backchannels.
  /// "mm-hmm oo" is zero; "teka lang" is two.
  static int _meaningfulWords(String transcript) => transcript
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where(
        (word) => word.isNotEmpty && !VoiceBargeIn.backchannels.contains(word),
      )
      .length;

  void _releaseAsFalseAlarm() {
    _falseAlarmTimer = null;
    if (_confirmed || !_ducked) return;
    _ducked = false;
    onRelease();
  }

  /// Back to neutral — a new assistant turn, or the current one ending.
  ///
  /// Releases an outstanding duck on the way out; without that a turn ending
  /// while ducked leaves the player turned down for every reply after it.
  /// Not released after a confirmed interruption: that turn is being torn
  /// down and its volume restored by the stop path.
  void reset() {
    _falseAlarmTimer?.cancel();
    _falseAlarmTimer = null;
    final wasDuckedWithoutConfirming = _ducked && !_confirmed;
    _ducked = false;
    _confirmed = false;
    if (wasDuckedWithoutConfirming) onRelease();
  }

  void dispose() {
    _falseAlarmTimer?.cancel();
    _falseAlarmTimer = null;
  }
}
