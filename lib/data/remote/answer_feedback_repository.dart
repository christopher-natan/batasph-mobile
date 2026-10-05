import 'package:batasph_mobile/data/models/answer_feedback_model.dart';
import 'package:batasph_mobile/data/models/chat_message_model.dart';
import 'package:batasph_mobile/data/remote/api_client.dart';

class AnswerFeedbackRepository {
  final _client = ApiClient().client;

  Future<AnswerFeedbackModel> submitFeedback({
    required ChatMessageModel questionMessage,
    required ChatMessageModel answerMessage,
    required AnswerFeedbackIssueType issueType,
    String? comment,
  }) async {
    final response = await _client.post(
      '/answer-feedback',
      data: {
        'questionMessageId': questionMessage.id,
        'answerMessageId': answerMessage.id,
        'question': questionMessage.text,
        'answer': answerMessage.text,
        'answerStatus': answerMessage.status,
        'responseLanguage': answerMessage.responseLanguage,
        'issueType': issueType.apiValue,
        if (comment != null && comment.trim().isNotEmpty) 'comment': comment,
      },
    );

    return AnswerFeedbackModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<AnswerFeedbackModel>> getFeedbackReports() async {
    final response = await _client.get('/answer-feedback');
    final items = response.data as List;

    return items
        .map(
          (item) => AnswerFeedbackModel.fromJson(item as Map<String, dynamic>),
        )
        .toList(growable: false);
  }
}
