import 'package:get/get.dart';
import 'package:batasph_mobile/services/auth_service.dart';
import 'package:batasph_mobile/services/chat_service.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AuthService(), permanent: true);
    Get.put(ChatService(), permanent: true);
  }
}
