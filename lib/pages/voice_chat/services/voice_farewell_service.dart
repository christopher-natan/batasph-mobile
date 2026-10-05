class VoiceFarewellService {
  static String silenceCheckIn({required String language}) {
    return language == 'tagalog'
        ? 'Hello, nandiyan ka pa ba? May iba ka pa bang tanong tungkol sa legal concern mo?'
        : 'Hello, are you still there? Do you have another question about your legal concern?';
  }

  static String silenceFarewell({required String language}) {
    return language == 'tagalog'
        ? 'Mukhang wala ka na sa linya. Salamat sa pagtawag sa BatasPH. Maaari kang tumawag ulit anumang oras. Ingat, paalam!'
        : 'It seems you are no longer on the line. Thank you for calling BatasPH. You can call again anytime. Take care, goodbye!';
  }

  static String? replyFor(String transcript, {required String language}) {
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

    if (!isFarewell) return null;
    return language == 'tagalog'
        ? 'Salamat sa pagtawag sa BatasPH. Ingat, paalam!'
        : 'Thank you for calling BatasPH. Take care, goodbye!';
  }
}
