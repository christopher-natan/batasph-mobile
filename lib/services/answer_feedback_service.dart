import 'package:get/get.dart';
import 'package:batasph_mobile/data/models/answer_feedback_model.dart';
import 'package:batasph_mobile/data/models/chat_message_model.dart';
import 'package:batasph_mobile/data/remote/answer_feedback_repository.dart';
import 'package:batasph_mobile/utils/logger_util.dart';

class AnswerFeedbackService extends GetxService {
  final _repository = AnswerFeedbackRepository();

  final feedbackReports = <AnswerFeedbackModel>[].obs;
  final isLoaded = false.obs;

  @override
  void onInit() {
    super.onInit();
    refreshReports();
  }

  Future<void> refreshReports() async {
    try {
      final items = await _repository.getFeedbackReports();
      BatasphLogger.log('[Feedback] Reports loaded | count=${items.length}');
      feedbackReports.assignAll(items);
    } catch (error, stackTrace) {
      BatasphLogger.warning(
        '[Feedback] Failed to load reports',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      isLoaded.value = true;
    }
  }

  Future<AnswerFeedbackModel> submitFeedback({
    required ChatMessageModel questionMessage,
    required ChatMessageModel answerMessage,
    required AnswerFeedbackIssueType issueType,
    String? comment,
  }) async {
    final created = await _repository.submitFeedback(
      questionMessage: questionMessage,
      answerMessage: answerMessage,
      issueType: issueType,
      comment: comment,
    );

    feedbackReports.removeWhere((item) => item.id == created.id);
    feedbackReports.insert(0, created);
    isLoaded.value = true;
    return created;
  }
}
