import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:batasph_mobile/data/local/my_shared_pref.dart';
import 'package:batasph_mobile/routes/app_pages.dart';
import 'package:batasph_mobile/utils/logger_util.dart';

class OnboardingController extends GetxController {
  final pageController = PageController();
  final currentPage = 0.obs;

  static const totalPages = 3;

  bool get isLastPage => currentPage.value == totalPages - 1;

  void nextPage() {
    if (isLastPage) {
      completeOnboarding();
    } else {
      pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void skip() {
    BatasphLogger.log('[Onboarding] Skipped at page ${currentPage.value}');
    completeOnboarding();
  }

  void onPageChanged(int page) {
    currentPage.value = page;
  }

  void completeOnboarding() {
    BatasphLogger.log('[Onboarding] Complete');
    MySharedPref.setOnboardingComplete();
    Get.offAllNamed(Routes.MAIN_SHELL);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
