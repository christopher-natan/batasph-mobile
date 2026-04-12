import 'package:get/get.dart';
import 'package:batasph_mobile/pages/register/register_controller.dart';

class RegisterBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => RegisterController());
  }
}
