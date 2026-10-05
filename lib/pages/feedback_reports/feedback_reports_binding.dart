import 'package:get/get.dart';
import 'package:batasph_mobile/pages/feedback_reports/feedback_reports_controller.dart';

class FeedbackReportsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FeedbackReportsController>(FeedbackReportsController.new);
  }
}
