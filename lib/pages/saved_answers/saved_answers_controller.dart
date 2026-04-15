import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:batasph_mobile/data/models/saved_answer_model.dart';
import 'package:batasph_mobile/services/saved_answers_service.dart';

class SavedAnswersController extends GetxController {
  final _savedAnswersService = Get.find<SavedAnswersService>();

  final searchController = TextEditingController();
  final searchQuery = ''.obs;

  RxList<SavedAnswerModel> get savedAnswers =>
      _savedAnswersService.savedAnswers;

  List<SavedAnswerModel> get filteredAnswers {
    final query = searchQuery.value.trim();
    if (query.isEmpty) {
      return savedAnswers;
    }

    return savedAnswers.where((item) => item.matchesQuery(query)).toList();
  }

  bool get hasSavedAnswers => savedAnswers.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(() {
      searchQuery.value = searchController.text;
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> removeSavedAnswer(SavedAnswerModel item) {
    return _savedAnswersService.removeSavedAnswer(item.id);
  }

  Future<void> clearAll() async {
    await _savedAnswersService.clearAll();
    searchController.clear();
  }
}
