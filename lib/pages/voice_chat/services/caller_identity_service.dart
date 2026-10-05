import 'dart:math';

import 'package:dio/dio.dart';
import 'package:batasph_mobile/data/remote/api_client.dart';
import 'package:batasph_mobile/utils/logger_util.dart';

/// How the caller answered when Luna asked who is calling.
enum CallerReplyKind {
  /// Returning caller confirmed the saved name ("Yes", "Oo, ako nga").
  confirmed,

  /// Gave a name: a first-time caller's name, or a different one than saved.
  name,

  /// Said it is not them but gave no name ("No", "Hindi po").
  denied,

  /// Did not answer the question; went straight to their legal concern.
  question,

  /// Too short or unclear to tell.
  unclear,
}

class CallerReply {
  const CallerReply(this.kind, {this.name, this.question});

  factory CallerReply.fromJson(Map<String, dynamic> json) {
    final kind = CallerReplyKind.values.byName(json['kind'] as String);
    final name = json['name'] as String?;
    if (kind == CallerReplyKind.name && (name == null || name.isEmpty)) {
      throw const FormatException('Caller identity: name kind without a name');
    }
    return CallerReply(kind, name: name, question: json['question'] as String?);
  }

  final CallerReplyKind kind;

  /// First name, capitalised. Set only for [CallerReplyKind.name].
  final String? name;

  /// A legal question said in the same reply ("Si Chris to, may tanong
  /// ako…"), or the whole reply for [CallerReplyKind.question].
  final String? question;
}

/// Reads the caller's answer to "May I ask your name?" or "Am I speaking
/// with Chris again?", in English, Tagalog or Taglish, and picks Luna's
/// varied replies. The controller owns the conversation and storage.
///
/// [identify] asks the API, whose model understands any phrasing ("Chris
/// yung pangalan ko"). The on-phone readers ([readName],
/// [readConfirmation]) only know common patterns; they answer when the API
/// cannot be reached, so an offline call still moves on.
class CallerIdentityService {
  CallerIdentityService({Random? random}) : _random = random ?? Random();

  final Random _random;

  static const Duration _timeout = Duration(seconds: 6);

  /// What the caller's reply means. [savedName] is the name the greeting
  /// asked to confirm; null when it asked for a name.
  Future<CallerReply> identify(String transcript, {String? savedName}) async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await ApiClient().client.post(
        '/caller-identity',
        data: {'transcript': transcript, 'savedName': ?savedName},
        options: Options(receiveTimeout: _timeout, sendTimeout: _timeout),
      );
      final reply = CallerReply.fromJson(response.data as Map<String, dynamic>);
      BatasphLogger.log(
        '[Voice] Caller identity from API | ${stopwatch.elapsedMilliseconds}ms',
      );
      return reply;
    } catch (error, stackTrace) {
      BatasphLogger.warning(
        '[Voice] Caller identity API failed, reading on the phone'
        ' | ${stopwatch.elapsedMilliseconds}ms',
        error: error,
        stackTrace: stackTrace,
      );
      return savedName == null
          ? readName(transcript)
          : readConfirmation(transcript, savedName);
    }
  }

  // Sounds and greetings in front of the real answer.
  static const _leading = {
    'hi',
    'hello',
    'hey',
    'uh',
    'um',
    'uhm',
    'ah',
    'ahh',
    'ay',
    'eh',
    'oh',
    'well',
    'okay',
    'ok',
    'po',
    'ma\'am',
    'maam',
    'attorney',
    'atty',
    'luna',
  };
  static const _yes = {
    'yes',
    'yeah',
    'yep',
    'yup',
    'oo',
    'opo',
    'oho',
    'correct',
    'tama',
    'right',
    'sure',
    'speaking',
    'ako',
    'mismo',
  };
  static const _no = {'no', 'nope', 'hindi', 'di', 'not', 'nah'};

  // After one of these the next word is the name, however long the sentence.
  static const _strongIntros = [
    'my name is',
    'my names',
    'my name\'s',
    'the name is',
    'name is',
    'you can call me',
    'call me',
    'ang pangalan ko po ay',
    'ang pangalan ko ay',
    'ang pangalan ko po',
    'ang pangalan ko',
    'pangalan ko po ay',
    'pangalan ko ay',
    'pangalan ko po',
    'pangalan ko',
    'ako po ay si',
    'ako ay si',
    'ako po si',
    'ako si',
  ];

  // These also start ordinary sentences ("I'm asking about…"), so they only
  // count when a short name follows.
  static const _weakIntros = [
    'this is',
    'it is',
    'it\'s',
    'its',
    'i am',
    'i\'m',
    'im',
    'si',
  ];

  // Words that sit after a name ("Chris po", "Chris here", "si Chris ito").
  static const _trailing = {
    'po',
    'here',
    'speaking',
    'ito',
    'nga',
    'again',
    'ulit',
    'yes',
    'oo',
    'opo',
    'yeah',
    'ho',
    'naman',
    'lang',
  };

  // Words that can never be a name.
  static const _notNames = {
    'me',
    'you',
    'yes',
    'no',
    'not',
    'the',
    'a',
    'an',
    'fine',
    'good',
    'okay',
    'ok',
    'here',
    'sorry',
    'just',
    'asking',
    'calling',
    'wondering',
    'trying',
    'going',
    'looking',
    'having',
    'so',
    'and',
    'but',
    'what',
    'who',
    'why',
    'how',
    'when',
    'where',
    'ano',
    'sino',
    'bakit',
    'paano',
    'saan',
    'kailan',
    'ako',
    'ikaw',
    'siya',
    'kami',
    'tayo',
    'po',
    'opo',
    'oo',
    'hindi',
    'wala',
    'may',
    'meron',
    'gusto',
    'tanong',
    'question',
    'hello',
    'hi',
    'thanks',
    'salamat',
    'ito',
    'yan',
    'iyan',
    'yun',
    'iyon',
    'sige',
    'teka',
    'is',
    'are',
    'was',
    'his',
    'her',
    'it',
    'this',
    'that',
    'he',
    'she',
    'they',
    'we',
    'i',
    'im',
    "i'm",
    "it's",
    'its',
    "that's",
    'thats',
    'mismo',
    'nga',
    'again',
    'ulit',
    'lawyer',
    'attorney',
    'can',
    'do',
    'does',
    'my',
  };

  /// A turn this long without a name is the caller's question.
  static const int _questionMinWords = 4;

  /// The caller's answer to "May I ask your name?".
  static CallerReply readName(String transcript) {
    final words = _words(transcript);
    if (words.isEmpty) return const CallerReply(CallerReplyKind.unclear);
    final introduced = _nameAfterIntro(words);
    if (introduced != null) {
      return CallerReply(CallerReplyKind.name, name: introduced);
    }
    final bare = _bareName(_dropLeading(_dropYesNo(words)));
    if (bare != null) return CallerReply(CallerReplyKind.name, name: bare);
    return _questionOrUnclear(transcript, words);
  }

  /// The caller's answer to "Am I speaking with [savedName] again?".
  static CallerReply readConfirmation(String transcript, String savedName) {
    final words = _words(transcript);
    if (words.isEmpty) return const CallerReply(CallerReplyKind.unclear);

    CallerReply byName(String name) => isSameName(name, savedName)
        ? const CallerReply(CallerReplyKind.confirmed)
        : CallerReply(CallerReplyKind.name, name: name);

    final introduced = _nameAfterIntro(words);
    if (introduced != null) return byName(introduced);

    final first = words.first;
    final rest = _dropLeading(_dropYesNo(words));
    if (_no.contains(first)) {
      final named = _bareName(rest);
      return named == null
          ? const CallerReply(CallerReplyKind.denied)
          : CallerReply(CallerReplyKind.name, name: named);
    }
    if (_yes.contains(first)) {
      final named = _bareName(rest);
      return named == null
          ? const CallerReply(CallerReplyKind.confirmed)
          : byName(named);
    }
    final named = _bareName(words);
    if (named != null) return byName(named);
    return _questionOrUnclear(transcript, words);
  }

  static CallerReply _questionOrUnclear(
    String transcript,
    List<String> words,
  ) => words.length >= _questionMinWords
      ? CallerReply(CallerReplyKind.question, question: transcript.trim())
      : const CallerReply(CallerReplyKind.unclear);

  static List<String> _words(String transcript) => _dropLeading(
    transcript
        .toLowerCase()
        .replaceAll(RegExp(r'[‘’`]'), "'")
        .replaceAll(RegExp(r"[^a-zñ'\s-]"), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList(),
  );

  static List<String> _dropLeading(List<String> words) {
    var start = 0;
    while (start < words.length && _leading.contains(words[start])) {
      start++;
    }
    return words.sublist(start);
  }

  /// Drops a leading "yes"/"no" (and anything like it) so the name after it
  /// can be read: "No, si Maria ito", "Yes, Chris".
  static List<String> _dropYesNo(List<String> words) {
    var start = 0;
    while (start < words.length &&
        (_yes.contains(words[start]) ||
            _no.contains(words[start]) ||
            _leading.contains(words[start]))) {
      start++;
    }
    return words.sublist(start);
  }

  static String? _nameAfterIntro(List<String> words) {
    final body = _dropYesNo(words);
    final joined = body.join(' ');
    for (final intro in _strongIntros) {
      if (joined.startsWith('$intro ')) {
        final after = body.sublist(intro.split(' ').length);
        return after.isEmpty ? null : _asName(after.first);
      }
    }
    for (final intro in _weakIntros) {
      if (joined.startsWith('$intro ')) {
        return _bareName(body.sublist(intro.split(' ').length));
      }
    }
    return null;
  }

  /// A name said on its own: up to three words ("Juan dela Cruz"), none of
  /// them a word that cannot be a name, with only polite or filler words
  /// after it. Luna uses the first name.
  static String? _bareName(List<String> words) {
    final core = [...words];
    while (core.isNotEmpty && _trailing.contains(core.last)) {
      core.removeLast();
    }
    if (core.isEmpty || core.length > 3) return null;
    if (core.any(_notNames.contains)) return null;
    return _asName(core.first);
  }

  static String? _asName(String word) {
    final clean = word.replaceAll(RegExp(r"^['-]+|['-]+$"), '');
    if (clean.length < 2 || _notNames.contains(clean)) return null;
    return clean[0].toUpperCase() + clean.substring(1);
  }

  static bool isSameName(String a, String b) =>
      a.toLowerCase() == b.trim().split(RegExp(r'\s+')).first.toLowerCase();

  // ─── Luna's replies ────────────────────────────────────────

  String welcomeNew(String name) => _pick([
    'Hi, $name! How can I help you today?',
    'Nice to meet you, $name! Ano ang maitutulong ko sa\'yo today?',
    'Hello, $name! Ano ang legal concern mo ngayon?',
  ]);

  String welcomeBack(String name) => _pick([
    'Welcome back, $name! How can I help you today?',
    'Great to hear from you again, $name! Ano ang maitutulong ko ngayon?',
    'Hi again, $name! Ano ang tanong mo today?',
  ]);

  String nameUpdated(String name) => _pick([
    'Thanks for letting me know, $name. How can I help you today?',
    'Ay, sorry about that! Hi, $name. Ano ang maitutulong ko sa\'yo?',
    'Got it, $name, thank you! How can I help you today?',
  ]);

  String askNameAfterDenial() => _pick([
    'Ay, sorry about that! May I ask your name?',
    'Pasensya na! Ano ang pangalan mo?',
  ]);

  String askNameAgain() => _pick([
    'Sorry, hindi ko masyadong nakuha. Ano ulit ang pangalan mo?',
    'Pasensya na, can you say your name again?',
  ]);

  String skipName() => _pick([
    'No problem! How can I help you today?',
    'Okay lang yan. Ano ang maitutulong ko sa\'yo today?',
  ]);

  String _pick(List<String> lines) => lines[_random.nextInt(lines.length)];
}
