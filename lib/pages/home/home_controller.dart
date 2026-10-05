import 'package:get/get.dart';
import 'package:batasph_mobile/routes/app_pages.dart';
import 'package:batasph_mobile/utils/logger_util.dart';

/// The ready-to-call screen.
class HomeController extends GetxController {
  void startCall() {
    BatasphLogger.log('[Home] Call');
    Get.toNamed(Routes.VOICE_CHAT);
  }

  void openSettings() {
    Get.toNamed(Routes.SETTINGS);
  }
}
