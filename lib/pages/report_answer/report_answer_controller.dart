import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:batasph_mobile/data/models/answer_feedback_model.dart';
import 'package:batasph_mobile/pages/report_answer/report_answer_arguments.dart';
import 'package:batasph_mobile/services/answer_feedback_service.dart';
import 'package:batasph_mobile/utils/logger_util.dart';

class ReportAnswerController extends GetxController {
  final _answerFeedbackService = Get.find<AnswerFeedbackService>();

  late final ReportAnswerArguments arguments;
  final commentController = TextEditingController();
  final selectedIssueType = AnswerFeedbackIssueType.wrongAnswer.obs;
  final isSubmitting = false.obs;

  @override
  void onInit() {
    super.onInit();
    final routeArgs = Get.arguments;
    if (routeArgs is! ReportAnswerArguments) {
      throw StateError('ReportAnswerPage requires ReportAnswerArguments');
    }
    arguments = routeArgs;
  }

  @override
  void onClose() {
    commentController.dispose();
    super.onClose();
  }

  Future<void> submitReport() async {
    if (isSubmitting.value) {
      return;
    }

    isSubmitting.value = true;
    BatasphLogger.log(
      '[Feedback] Submitting report | answer=${arguments.answerMessage.id}'
      ' | issue=${selectedIssueType.value}'
      ' | commentChars=${commentController.text.trim().length}',
    );
    try {
      await _answerFeedbackService.submitFeedback(
        questionMessage: arguments.questionMessage,
        answerMessage: arguments.answerMessage,
        issueType: selectedIssueType.value,
        comment: commentController.text.trim(),
      );

      Get.back(result: true);
      Get.snackbar(
        'Report sent',
        'Your feedback was saved so this answer can be reviewed.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error, stackTrace) {
      BatasphLogger.error(
        '[Feedback] Failed to submit report',
        error: error,
        stackTrace: stackTrace,
      );
      Get.snackbar(
        'Unable to send report',
        'Try again in a moment.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSubmitting.value = false;
    }
  }
}
