import 'package:get/get.dart';
import 'package:batasph_mobile/pages/chat/chat_controller.dart';
import 'package:batasph_mobile/pages/home/home_controller.dart';
import 'package:batasph_mobile/pages/main_shell/main_shell_controller.dart';
import 'package:batasph_mobile/pages/settings/settings_controller.dart';
import 'package:batasph_mobile/pages/sources/sources_controller.dart';

class MainShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => MainShellController());
    Get.lazyPut(() => HomeController());
    Get.lazyPut(() => ChatController());
    Get.lazyPut(() => SourcesController());
    Get.lazyPut(() => SettingsController());
  }
}
