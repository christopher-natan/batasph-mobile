import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:batasph_mobile/data/models/answer_feedback_model.dart';
import 'package:batasph_mobile/services/answer_feedback_service.dart';

class FeedbackReportsController extends GetxController {
  final _answerFeedbackService = Get.find<AnswerFeedbackService>();

  final searchController = TextEditingController();
  final searchQuery = ''.obs;

  RxList<AnswerFeedbackModel> get feedbackReports =>
      _answerFeedbackService.feedbackReports;

  bool get isLoaded => _answerFeedbackService.isLoaded.value;

  List<AnswerFeedbackModel> get filteredReports {
    final query = searchQuery.value.trim();
    if (query.isEmpty) {
      return feedbackReports;
    }

    return feedbackReports
        .where((item) => item.matchesQuery(query))
        .toList(growable: false);
  }

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(() {
      searchQuery.value = searchController.text;
    });
    _answerFeedbackService.refreshReports();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
