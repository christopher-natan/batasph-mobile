import 'package:get/get.dart';
import 'package:batasph_mobile/pages/legal_webview/legal_webview_controller.dart';

class LegalWebViewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LegalWebViewController());
  }
}
