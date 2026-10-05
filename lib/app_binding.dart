import 'package:get/get.dart';
import 'package:batasph_mobile/services/auth_service.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AuthService(), permanent: true);
  }
}
