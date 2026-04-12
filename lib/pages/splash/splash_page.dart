import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:batasph_mobile/pages/splash/splash_controller.dart';

class SplashPage extends GetView<SplashController> {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F2420) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final taglineColor = isDark ? Colors.white54 : const Color(0xFF6F7E8D);

    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 100.w,
              height: 100.w,
            ),
            SizedBox(height: 20.h),
            Text(
              'BatasPH',
              style: TextStyle(
                fontSize: 40.sp,
                fontWeight: FontWeight.w800,
                color: titleColor,
                letterSpacing: -1.2,
                height: 1,
              ),
            ),
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
