import 'package:get/get.dart';
import 'package:batasph_mobile/pages/report_answer/report_answer_controller.dart';

class ReportAnswerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReportAnswerController>(ReportAnswerController.new);
  }
}
