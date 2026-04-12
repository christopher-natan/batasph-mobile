import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart' as webview;

class LegalWebViewController extends GetxController {
  static const String titleKey = 'title';
  static const String urlKey = 'url';

  late final String pageTitle;
  late final String initialUrl;
  late final webview.WebViewController webViewController;

  final loadingProgress = 0.obs;
  final hasMainFrameError = false.obs;
  final errorDescription = ''.obs;

  @override
  void onInit() {
    super.onInit();
    final arguments = Get.arguments;
    if (arguments is! Map) {
      throw ArgumentError(
        'Legal webview route requires title and url arguments.',
      );
    }

    final title = arguments[titleKey]?.toString();
    final url = arguments[urlKey]?.toString();
    if (title == null || title.isEmpty || url == null || url.isEmpty) {
      throw ArgumentError(
        'Legal webview route requires non-empty title and url arguments.',
      );
    }

    pageTitle = title;
    initialUrl = url;
    webViewController = webview.WebViewController()
      ..setJavaScriptMode(webview.JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        webview.NavigationDelegate(
          onProgress: (progress) {
            loadingProgress.value = progress.clamp(0, 100).toInt();
          },
          onPageStarted: (_) {
            hasMainFrameError.value = false;
            errorDescription.value = '';
            loadingProgress.value = 0;
          },
          onPageFinished: (_) {
            loadingProgress.value = 100;
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame != true) {
              return;
            }
            hasMainFrameError.value = true;
            errorDescription.value = error.description;
            loadingProgress.value = 100;
          },
        ),
      )
      ..loadRequest(Uri.parse(initialUrl));
  }

  Future<void> reload() async {
    hasMainFrameError.value = false;
    errorDescription.value = '';
    loadingProgress.value = 0;
    await webViewController.reload();
  }
}
