import 'package:get/get.dart';
import 'package:batasph_mobile/pages/home/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => HomeController());
  }
}
