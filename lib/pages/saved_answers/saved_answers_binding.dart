import 'package:get/get.dart';
import 'package:batasph_mobile/pages/saved_answers/saved_answers_controller.dart';

class SavedAnswersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SavedAnswersController());
  }
}
