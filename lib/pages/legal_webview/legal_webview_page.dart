import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart' as webview;
import 'package:batasph_mobile/pages/legal_webview/legal_webview_controller.dart';

class LegalWebViewPage extends GetView<LegalWebViewController> {
  const LegalWebViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          controller.pageTitle,
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: controller.reload,
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload',
          ),
        ],
      ),
      body: Column(
        children: [
          Obx(() {
            final progress = controller.loadingProgress.value;
            if (controller.hasMainFrameError.value || progress >= 100) {
              return const SizedBox.shrink();
            }

            return LinearProgressIndicator(
              minHeight: 2.h,
              value: progress == 0 ? null : progress / 100,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.08),
            );
          }),
          Expanded(
            child: Obx(() {
              if (controller.hasMainFrameError.value) {
                return _LegalLoadError(
                  theme: theme,
                  errorDescription: controller.errorDescription.value,
                  onRetry: controller.reload,
                );
              }

              return webview.WebViewWidget(
                controller: controller.webViewController,
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _LegalLoadError extends StatelessWidget {
  const _LegalLoadError({
    required this.theme,
    required this.errorDescription,
    required this.onRetry,
  });

  final ThemeData theme;
  final String errorDescription;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56.w,
              height: 56.w,
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_rounded,
                size: 26.sp,
                color: theme.colorScheme.error,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Unable to load page',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            if (errorDescription.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Text(
                errorDescription,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: theme.hintColor,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            SizedBox(height: 20.h),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
