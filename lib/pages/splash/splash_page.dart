import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:batasph_mobile/pages/splash/splash_controller.dart';

class SplashPage extends GetView<SplashController> {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF2C3550);
    const titleColor = Color(0xFFF5F1EA);
    const taglineColor = Color(0xFFD7A96A);

    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 132.w,
              height: 132.w,
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
