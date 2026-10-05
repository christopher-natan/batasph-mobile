import 'package:get/get.dart';
import 'package:batasph_mobile/pages/verify_email/verify_email_controller.dart';

class VerifyEmailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => VerifyEmailController());
  }
}
