import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:batasph_mobile/components/brand_logo_component.dart';
import 'package:batasph_mobile/config/theme/app_themes.dart';
import 'package:batasph_mobile/pages/splash/splash_controller.dart';

class SplashPage extends GetView<SplashController> {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    const bg = AppThemes.ivory;
    const taglineColor = AppThemes.muted;

    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandLogoComponent(markSize: 132.w, fontSize: 40.sp, stacked: true),
            SizedBox(height: 8.h),
            Text(
              'Philippine laws, explained simply',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w400,
                color: taglineColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
