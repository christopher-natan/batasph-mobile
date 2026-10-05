enum AnswerFeedbackIssueType {
  wrongAnswer,
  missingLaw,
  needsClearerExplanation,
  outdated,
  other;

  String get apiValue => switch (this) {
    AnswerFeedbackIssueType.wrongAnswer => 'wrong_answer',
    AnswerFeedbackIssueType.missingLaw => 'missing_law',
    AnswerFeedbackIssueType.needsClearerExplanation =>
      'needs_clearer_explanation',
    AnswerFeedbackIssueType.outdated => 'outdated',
    AnswerFeedbackIssueType.other => 'other',
  };

  String get label => switch (this) {
    AnswerFeedbackIssueType.wrongAnswer => 'Wrong answer',
    AnswerFeedbackIssueType.missingLaw => 'Missing law',
    AnswerFeedbackIssueType.needsClearerExplanation =>
      'Needs clearer explanation',
    AnswerFeedbackIssueType.outdated => 'Outdated',
    AnswerFeedbackIssueType.other => 'Other',
  };

  String get description => switch (this) {
    AnswerFeedbackIssueType.wrongAnswer =>
      'The answer appears incorrect or misleading.',
    AnswerFeedbackIssueType.missingLaw =>
      'The answer missed a law, section, or legal basis that should have been included.',
    AnswerFeedbackIssueType.needsClearerExplanation =>
      'The answer is too technical, confusing, or not direct enough.',
    AnswerFeedbackIssueType.outdated =>
      'The answer may no longer match the current law or implementation.',
    AnswerFeedbackIssueType.other =>
      'Something else is wrong with this answer.',
  };

  static AnswerFeedbackIssueType fromApiValue(String value) {
    return AnswerFeedbackIssueType.values.firstWhere(
      (item) => item.apiValue == value,
      orElse: () => AnswerFeedbackIssueType.other,
    );
  }
}

class AnswerFeedbackModel {
  final String id;
  final String questionMessageId;
  final String answerMessageId;
  final String question;
  final String answer;
  final String answerStatus;
  final String responseLanguage;
  final AnswerFeedbackIssueType issueType;
  final String comment;
  final String reviewStatus;
  final DateTime createdAt;

  const AnswerFeedbackModel({
    required this.id,
    required this.questionMessageId,
    required this.answerMessageId,
    required this.question,
    required this.answer,
    required this.answerStatus,
    required this.responseLanguage,
    required this.issueType,
    required this.comment,
    required this.reviewStatus,
    required this.createdAt,
  });

  bool matchesQuery(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }

    return question.toLowerCase().contains(normalized) ||
        answer.toLowerCase().contains(normalized) ||
        issueType.label.toLowerCase().contains(normalized) ||
        comment.toLowerCase().contains(normalized);
  }

  factory AnswerFeedbackModel.fromJson(Map<String, dynamic> json) {
    return AnswerFeedbackModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      questionMessageId: json['questionMessageId'] as String? ?? '',
      answerMessageId: json['answerMessageId'] as String? ?? '',
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      answerStatus: json['answerStatus'] as String? ?? '',
      responseLanguage: json['responseLanguage'] as String? ?? '',
      issueType: AnswerFeedbackIssueType.fromApiValue(
        json['issueType'] as String? ?? '',
      ),
      comment: json['comment'] as String? ?? '',
      reviewStatus: json['reviewStatus'] as String? ?? 'submitted',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
