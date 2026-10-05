import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:batasph_mobile/components/persona_avatar_component.dart';
import 'package:batasph_mobile/config/config.dart';
import 'package:batasph_mobile/config/theme/app_themes.dart';
import 'package:batasph_mobile/pages/onboarding/onboarding_controller.dart';

class OnboardingPage extends GetView<OnboardingController> {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(28.w, 24.h, 28.w, 28.h),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PersonaAvatarComponent(size: 148.w),
                    SizedBox(height: 28.h),
                    Text(
                      'Hi, I\'m ${AppConfig.personaName}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w600,
                        color: AppThemes.ink,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      AppConfig.personaTagline,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: AppThemes.forest,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      'Call me and ask about Philippine law out loud, in English, Tagalog or Taglish. I\'ll explain it simply and tell you which law my answer is based on.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15.sp,
                        height: 1.6,
                        color: AppThemes.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'I\'m an AI. This is general legal information, not legal advice.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.sp, color: AppThemes.muted),
              ),
              SizedBox(height: 16.h),
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 54.h,
                  child: FilledButton(
                    onPressed: controller.isContinuing.value
                        ? null
                        : controller.continueToApp,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppThemes.forest,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999.r),
                      ),
                    ),
                    child: Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                'You\'ll be asked to allow the microphone for calls.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.sp, color: AppThemes.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
