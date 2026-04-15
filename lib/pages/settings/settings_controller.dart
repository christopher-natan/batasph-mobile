import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:batasph_mobile/config/language/answer_language.dart';
import 'package:batasph_mobile/config/theme/app_themes.dart';
import 'package:batasph_mobile/config/theme/my_theme.dart';
import 'package:batasph_mobile/data/local/my_shared_pref.dart';
import 'package:batasph_mobile/data/models/user_model.dart';
import 'package:batasph_mobile/pages/chat/chat_controller.dart';
import 'package:batasph_mobile/pages/home/home_controller.dart';
import 'package:batasph_mobile/routes/app_pages.dart';
import 'package:batasph_mobile/services/auth_service.dart';
import 'package:batasph_mobile/services/saved_answers_service.dart';

class SettingsController extends GetxController {
  final _authService = Get.find<AuthService>();
  final _savedAnswersService = Get.find<SavedAnswersService>();

  final isDarkMode = (!MySharedPref.getThemeIsLight()).obs;
  final currentThemeId = MySharedPref.getAppTheme().obs;
  final answerLanguage = MySharedPref.getAnswerLanguage().obs;

  Rxn<UserModel> get currentUser => _authService.currentUser;

  bool get hasAccountSession =>
      _authService.isAuthenticated && currentUser.value != null;

  String get accountName {
    final name = currentUser.value?.name.trim() ?? '';
    return name.isEmpty ? 'BatasPH Account' : name;
  }

  String get accountSubtitle {
    final email = currentUser.value?.email.trim() ?? '';
    if (email.isNotEmpty) {
      return email;
    }
    return 'Sign in to prepare your BatasPH account profile.';
  }

  String get accountInitials => currentUser.value?.initials ?? 'BT';

  int get savedAnswersCount => _savedAnswersService.savedAnswers.length;

  void toggleDarkMode(bool value) {
    isDarkMode.value = value;
    MySharedPref.setThemeIsLight(!value);
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
  }

  void changeAppTheme(AppThemeId themeId) {
    currentThemeId.value = themeId.name;
    MyTheme.changeAppTheme(themeId);
  }

  void changeAnswerLanguage(AnswerLanguage language) {
    answerLanguage.value = language;
    MySharedPref.setAnswerLanguage(language);
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().updateAnswerLanguage(language);
    }
    if (Get.isRegistered<ChatController>()) {
      Get.find<ChatController>().updateAnswerLanguage(language);
    }
  }

  void openLogin() {
    Get.toNamed(Routes.LOGIN);
  }

  void openRegister() {
    Get.toNamed(Routes.REGISTER);
  }

  void openProfile() {
    if (!hasAccountSession) {
      openLogin();
      return;
    }
    Get.toNamed(Routes.PROFILE);
  }

  void openVoiceSettings() {
    Get.toNamed(Routes.VOICE_SETTINGS);
  }

  void openSavedAnswers() {
    Get.toNamed(Routes.SAVED_ANSWERS);
  }

  Future<void> logout() async {
    await _authService.logout();
    Get.snackbar(
      'Signed out',
      'Your BatasPH account session has been cleared.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
