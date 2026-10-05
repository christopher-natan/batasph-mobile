/// What the assistant says the instant the user's transcript is final, so
/// there is no silence while the backend searches the law and writes.
///
/// Played BEFORE the answer is known, so every phrase must fit any
/// question. Short on purpose: the thinking loop carries the rest of the
/// wait. Bump [version] when the wording changes so cached audio is not
/// replayed.
///
/// Two pools, chosen by how much the user said:
///   - [checking]: for a real question ("can my employer fire me for that?")
///   - [acknowledging]: for one- or two-word turns ("okay", "you there?"),
///     where "Checking." would sound odd but silence is worse.
class VoiceFillers {
  VoiceFillers._();

  static const int version = 1;

  /// Turns with more words than this get a [checking] filler.
  static const int shortTurnMaxWords = 2;

  static const List<String> checking = [
    'Checking.',
    'Let me look.',
    'One moment.',
    'Let me check the law on that.',
    'Let me find that.',
    'Let me see.',
    'One sec.',
  ];

  static const List<String> acknowledging = [
    'Okay.',
    'Mm-hm.',
    'Sure.',
    'Right.',
    'Got it.',
  ];

  static bool isShortTurn(String text) {
    final words = text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    return words.length <= shortTurnMaxWords;
  }
}
