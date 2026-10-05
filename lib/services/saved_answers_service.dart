import 'dart:convert';

import 'package:get/get.dart';
import 'package:batasph_mobile/data/local/my_shared_pref.dart';
import 'package:batasph_mobile/data/models/chat_message_model.dart';
import 'package:batasph_mobile/data/models/saved_answer_model.dart';
import 'package:batasph_mobile/utils/logger_util.dart';

class SavedAnswersService extends GetxService {
  final savedAnswers = <SavedAnswerModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _hydrate();
  }

  bool isSaved(String answerMessageId) =>
      savedAnswers.any((item) => item.id == answerMessageId);

  Future<bool> toggleSavedAnswer({
    required ChatMessageModel questionMessage,
    required ChatMessageModel answerMessage,
  }) async {
    final existingIndex = savedAnswers.indexWhere(
      (item) => item.id == answerMessage.id,
    );
    if (existingIndex != -1) {
      savedAnswers.removeAt(existingIndex);
      await _persist();
      return false;
    }

    savedAnswers.insert(
      0,
      SavedAnswerModel.fromMessages(
        questionMessage: questionMessage,
        answerMessage: answerMessage,
      ),
    );
    await _persist();
    return true;
  }

  Future<void> removeSavedAnswer(String savedAnswerId) async {
    savedAnswers.removeWhere((item) => item.id == savedAnswerId);
    await _persist();
  }

  Future<void> clearAll() async {
    savedAnswers.clear();
    await MySharedPref.clearSavedAnswers();
  }

  void _hydrate() {
    final storedItems = MySharedPref.getSavedAnswers();
    final parsedItems = <SavedAnswerModel>[];

    for (final item in storedItems) {
      try {
        parsedItems.add(
          SavedAnswerModel.fromJson(jsonDecode(item) as Map<String, dynamic>),
        );
      } catch (error, stackTrace) {
        BatasphLogger.warning(
          '[Saved] Failed to parse saved answer, skipping',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    parsedItems.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    savedAnswers.assignAll(parsedItems);
  }

  Future<void> _persist() async {
    final payload = savedAnswers
        .map((item) => jsonEncode(item.toJson()))
        .toList(growable: false);
    await MySharedPref.setSavedAnswers(payload);
  }
}
