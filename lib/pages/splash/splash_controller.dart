import 'package:get/get.dart';
import 'package:batasph_mobile/data/local/my_shared_pref.dart';
import 'package:batasph_mobile/routes/app_pages.dart';
import 'package:batasph_mobile/utils/logger_util.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.delayed(const Duration(milliseconds: 1600));

    if (!MySharedPref.isOnboardingComplete()) {
      BatasphLogger.log('[Splash] Onboarding not complete -> onboarding');
      Get.offAllNamed(Routes.ONBOARDING);
      return;
    }

    BatasphLogger.log('[Splash] -> main shell');
    Get.offAllNamed(Routes.MAIN_SHELL);
  }
}
