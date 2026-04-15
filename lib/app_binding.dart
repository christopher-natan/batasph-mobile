import 'package:get/get.dart';
import 'package:batasph_mobile/services/auth_service.dart';
import 'package:batasph_mobile/services/chat_service.dart';
import 'package:batasph_mobile/services/saved_answers_service.dart';
import 'package:batasph_mobile/services/sources_service.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AuthService(), permanent: true);
    Get.put(ChatService(), permanent: true);
    Get.put(SavedAnswersService(), permanent: true);
    Get.put(SourcesService(), permanent: true);
  }
}
