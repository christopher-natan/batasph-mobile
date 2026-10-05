import 'package:get/get.dart';
import 'package:batasph_mobile/pages/settings/settings_controller.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SettingsController());
  }
}
