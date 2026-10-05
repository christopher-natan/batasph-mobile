import 'package:get/get.dart';
import 'package:batasph_mobile/config/language/answer_language.dart';
import 'package:batasph_mobile/data/local/my_shared_pref.dart';
import 'package:batasph_mobile/pages/chat/chat_controller.dart';
import 'package:batasph_mobile/pages/home/models/starter_question_model.dart';
import 'package:batasph_mobile/pages/home/services/home_starter_questions_service.dart';
import 'package:batasph_mobile/pages/main_shell/main_shell_controller.dart';
import 'package:batasph_mobile/routes/app_pages.dart';
import 'package:batasph_mobile/utils/logger_util.dart';

class HomeController extends GetxController {
  final _starterQuestionsService = HomeStarterQuestionsService();

  final quickSubjects = const [
    'Constitution',
    'Traffic Law',
    'Workers\' Rights',
  ];

  final starterQuestions = <StarterQuestionModel>[].obs;
  final isLoadingStarterQuestions = false.obs;
  final starterQuestionsError = ''.obs;
  final answerLanguage = MySharedPref.getAnswerLanguage().obs;

  @override
  void onInit() {
    super.onInit();
    loadStarterQuestions();
  }

  void openAskBatas([String? question]) {
    Get.find<MainShellController>().changeTab(1);
    if (question != null && question.trim().isNotEmpty) {
      Get.find<ChatController>().askStarterQuestion(question);
    }
  }

  void openVoiceChat() {
    Get.toNamed(Routes.VOICE_CHAT);
  }

  void openSavedAnswers() {
    Get.toNamed(Routes.SAVED_ANSWERS);
  }

  Future<void> loadStarterQuestions() async {
    isLoadingStarterQuestions.value = true;
    starterQuestionsError.value = '';

    try {
      final questions = await _starterQuestionsService.getRandomQuestions();
      BatasphLogger.log(
        '[Home] Starter questions loaded | count=${questions.length}',
      );
      starterQuestions.assignAll(questions);
    } catch (error, stackTrace) {
      BatasphLogger.error(
        '[Home] Failed to load starter questions',
        error: error,
        stackTrace: stackTrace,
      );
      starterQuestions.clear();
      starterQuestionsError.value =
          'Unable to load starter questions right now.';
    } finally {
      isLoadingStarterQuestions.value = false;
    }
  }

  void updateAnswerLanguage(AnswerLanguage language) {
    answerLanguage.value = language;
  }
}
