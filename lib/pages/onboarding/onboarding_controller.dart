import 'package:get/get.dart';
import 'package:record/record.dart';
import 'package:batasph_mobile/data/local/my_shared_pref.dart';
import 'package:batasph_mobile/routes/app_pages.dart';
import 'package:batasph_mobile/utils/logger_util.dart';

class OnboardingController extends GetxController {
  final isContinuing = false.obs;

  /// Asks for the microphone up front, since every answer starts with a call.
  /// A denial is not a dead end: the call asks again when it starts.
  Future<void> continueToApp() async {
    if (isContinuing.value) return;
    isContinuing.value = true;
    try {
      final recorder = AudioRecorder();
      try {
        final granted = await recorder.hasPermission();
        BatasphLogger.log('[Onboarding] Mic permission: $granted');
      } finally {
        recorder.dispose();
      }
      BatasphLogger.log('[Onboarding] Complete');
      await MySharedPref.setOnboardingComplete();
      Get.offAllNamed(Routes.HOME);
    } catch (e, st) {
      BatasphLogger.error(
        '[Onboarding] Continue failed',
        error: e,
        stackTrace: st,
      );
      isContinuing.value = false;
    }
  }
}
