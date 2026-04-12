import 'package:batasph_mobile/config/language/answer_language.dart';

class StarterQuestionModel {
  final String id;
  final String code;
  final String englishText;
  final String filipinoText;
  final List<String> subjects;

  const StarterQuestionModel({
    required this.id,
    required this.code,
    required this.englishText,
    required this.filipinoText,
    this.subjects = const [],
  });

  String textFor(AnswerLanguage language) {
    if (language == AnswerLanguage.tagalog) {
      return filipinoText;
    }
    return englishText;
  }

  String alternateTextFor(AnswerLanguage language) {
    if (language == AnswerLanguage.tagalog) {
      return englishText;
    }
    return filipinoText;
  }

  factory StarterQuestionModel.fromJson(Map<String, dynamic> json) {
    return StarterQuestionModel(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      englishText: json['englishText'] as String? ?? '',
      filipinoText: json['filipinoText'] as String? ?? '',
      subjects: json['subjects'] != null
          ? List<String>.from(json['subjects'] as List)
          : const [],
    );
  }
}
