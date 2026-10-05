/// Rejects a transcript that is really the assistant hearing itself.
/// Ported from Memori.
///
/// The microphone reopens the moment a reply finishes, but the device's
/// output buffer still has audio in flight and the room adds reverb, so the
/// tail of our own sentence can be captured and transcribed — and then sent
/// back to the backend as if the user had asked it. The controller's
/// mic-reopen guard shortens that window; this catches what still gets
/// through, and is the same comparison barge-in uses to tell a real
/// interruption from residual echo.
///
/// Deliberately strict: rejecting a real user turn is worse than letting one
/// echo through, so a match needs a run of consecutive words, not a bag of
/// shared ones.
class EchoTextGuard {
  /// Below this, a transcript is too short to judge.
  static const minWords = 4;

  /// A run of this many consecutive words in common is echo on its own.
  static const minConsecutiveWords = 4;

  /// Or a shorter run, if it covers this much of the transcript.
  static const minCoverage = 0.7;

  List<String> _spoken = const [];

  /// Records what the assistant is saying (or just said).
  void remember(String spokenText) {
    _spoken = _tokenize(spokenText);
  }

  /// Forgotten once a genuine user turn has been accepted, so the guard only
  /// ever applies to the window the echo lives in.
  void clear() {
    _spoken = const [];
  }

  /// True when [transcript] is our own voice coming back.
  bool looksLikeEcho(String transcript) {
    if (_spoken.isEmpty) return false;
    final heard = _tokenize(transcript);
    if (heard.length < minWords) return false;

    final run = _longestSharedRun(heard, _spoken);
    return run >= minConsecutiveWords || run / heard.length >= minCoverage;
  }

  static int _longestSharedRun(List<String> heard, List<String> spoken) {
    var best = 0;
    for (var i = 0; i < heard.length; i++) {
      for (var j = 0; j < spoken.length; j++) {
        var run = 0;
        while (i + run < heard.length &&
            j + run < spoken.length &&
            heard[i + run] == spoken[j + run]) {
          run++;
        }
        if (run > best) best = run;
      }
    }
    return best;
  }

  static List<String> _tokenize(String text) => text
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((word) => word.isNotEmpty)
      .toList();
}
