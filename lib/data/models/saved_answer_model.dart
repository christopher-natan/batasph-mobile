import 'package:batasph_mobile/data/models/chat_message_model.dart';

class SavedAnswerModel {
  final String id;
  final String question;
  final String questionMessageId;
  final ChatMessageModel answerMessage;
  final DateTime savedAt;

  const SavedAnswerModel({
    required this.id,
    required this.question,
    required this.questionMessageId,
    required this.answerMessage,
    required this.savedAt,
  });

  factory SavedAnswerModel.fromMessages({
    required ChatMessageModel questionMessage,
    required ChatMessageModel answerMessage,
  }) {
    return SavedAnswerModel(
      id: answerMessage.id,
      question: questionMessage.text.trim(),
      questionMessageId: questionMessage.id,
      answerMessage: answerMessage.copyWith(isUser: false),
      savedAt: DateTime.now(),
    );
  }

  factory SavedAnswerModel.fromJson(Map<String, dynamic> json) {
    return SavedAnswerModel(
      id: json['id'] as String? ?? '',
      question: json['question'] as String? ?? '',
      questionMessageId: json['questionMessageId'] as String? ?? '',
      answerMessage: ChatMessageModel.fromJson(
        Map<String, dynamic>.from(json['answerMessage'] as Map? ?? const {}),
      ),
      savedAt:
          DateTime.tryParse(json['savedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'question': question,
    'questionMessageId': questionMessageId,
    'answerMessage': answerMessage.toJson(),
    'savedAt': savedAt.toIso8601String(),
  };

  bool matchesQuery(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return true;
    }

    return question.toLowerCase().contains(normalizedQuery) ||
        answerMessage.text.toLowerCase().contains(normalizedQuery) ||
        (answerMessage.referenceLine ?? '').toLowerCase().contains(
          normalizedQuery,
        );
  }
}
