import 'package:get/get.dart';
import 'package:batasph_mobile/pages/voice_settings/voice_settings_controller.dart';

class VoiceSettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => VoiceSettingsController());
  }
}
