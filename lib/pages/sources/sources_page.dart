import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:batasph_mobile/pages/legal_webview/legal_webview_controller.dart';
import 'package:batasph_mobile/pages/sources/sources_controller.dart';
import 'package:batasph_mobile/routes/app_pages.dart';

class SourcesPage extends GetView<SourcesController> {
  const SourcesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sources',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView.builder(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
        itemCount: controller.sources.length,
        itemBuilder: (_, index) {
          final source = controller.sources[index];
          return Card(
            margin: EdgeInsets.only(bottom: 16.h),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    source.title,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    source.description,
                    style: TextStyle(fontSize: 13.sp, color: theme.hintColor),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    source.focus,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  ...source.laws.map(
                    (law) => Padding(
                      padding: EdgeInsets.only(bottom: 6.h),
                      child: Text('• $law'),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  ...source.links.map(
                    (link) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(link.label),
                      subtitle: Text(link.note),
                      trailing: const Icon(Icons.open_in_new_rounded),
                      onTap: () => Get.toNamed(
                        Routes.LEGAL_WEBVIEW,
                        arguments: {
                          LegalWebViewController.titleKey: link.label,
                          LegalWebViewController.urlKey: link.url,
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
