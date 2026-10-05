/// The call's fixed spoken lines, in Taglish like every answer.
class VoiceFarewellService {
  static const silenceCheckIn =
      'Hello, nandiyan ka pa ba? May iba ka pa bang tanong about your legal concern?';

  static const silenceFarewell =
      'Mukhang wala ka na sa linya. Thank you for calling BatasPH, pwede kang tumawag ulit anytime. Ingat, bye!';

  static const farewellReply = 'Thank you for calling BatasPH. Ingat ka, bye!';

  /// Said about thirty seconds before the five-minute limit.
  static const timeWarnings = [
    'Pasensya na, may thirty seconds na lang tayo bago matapos ang call. May gusto ka pa bang linawin? Pero pwede ka namang tumawag ulit anytime.',
    'Heads up, thirty seconds na lang ang natitira sa call natin. May gusto ka pa bang itanong? Tawag ka lang ulit kung kulang pa.',
  ];

  /// Said when the five minutes are up, then the call ends.
  static const timeUpFarewells = [
    'Ubos na ang oras natin for this call. Salamat sa pagtawag! Tawag ka lang ulit anytime. Ingat, bye!',
    "That's our five minutes for now. Thank you for calling BatasPH, pwede kang tumawag ulit anytime. Ingat!",
  ];

  /// The goodbye to speak when [transcript] is the caller ending the call,
  /// in English, Tagalog or Taglish; null for anything else.
  static String? replyFor(String transcript) {
    final normalized = transcript
        .toLowerCase()
        .replaceAll(RegExp(r'[‘’]'), "'")
        .replaceAll(RegExp(r"[^a-z0-9\s']"), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final isFarewell = RegExp(
      r"^(?:(?:okay|ok|sige|well|alright)\s+)?"
      r"(?:(?:thank you|thanks|thank u|salamat)(?:\s+po)?(?:\s+and)?\s+)?"
      r"(?:bye|goodbye|bye bye|paalam|that's all(?: for now)?|thats all(?: for now)?|"
      r"that is all(?: for now)?|yun lang(?: muna)?|iyon lang(?: muna)?|"
      r"wala na(?: po)?|tapos na(?: po)?)"
      r"(?:\s+(?:thank you|thanks|thank u|salamat)(?:\s+po)?)?$",
    ).hasMatch(normalized);

    return isFarewell ? farewellReply : null;
  }
}
