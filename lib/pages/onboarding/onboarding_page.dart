import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:batasph_mobile/pages/onboarding/onboarding_controller.dart';

class OnboardingPage extends GetView<OnboardingController> {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final pages = const [
      _OnboardingData(
        color: Color(0xFF2A8C7A),
        title: 'Ask real law questions',
        description:
            'Type practical questions about traffic rules, rights, and penalties in plain language.',
      ),
      _OnboardingData(
        color: Color(0xFF5B6ABF),
        title: 'See the legal basis',
        description:
            'BatasPH is designed to answer from raw law text and show the source used for the answer.',
      ),
      _OnboardingData(
        color: Color(0xFFD4853A),
        title: 'Start narrow, grow carefully',
        description:
            'Launch with a few strong legal subjects first, then expand the corpus without losing trust.',
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Obx(
                () => controller.isLastPage
                    ? SizedBox(height: 48.h)
                    : TextButton(
                        onPressed: controller.skip,
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: theme.hintColor,
                          ),
                        ),
                      ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: controller.pageController,
                onPageChanged: controller.onPageChanged,
                itemCount: OnboardingController.totalPages,
                itemBuilder: (_, index) => _buildPage(theme, pages[index]),
              ),
            ),
            Obx(
              () => Padding(
                padding: EdgeInsets.only(bottom: 32.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    OnboardingController.totalPages,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                      width: controller.currentPage.value == index ? 28.w : 8.w,
                      height: 8.w,
                      decoration: BoxDecoration(
                        color: controller.currentPage.value == index
                            ? theme.colorScheme.primary
                            : theme.colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
              child: Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: ElevatedButton(
                    onPressed: controller.nextPage,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                    ),
                    child: Text(
                      controller.isLastPage ? 'Open BatasPH' : 'Next',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(ThemeData theme, _OnboardingData data) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 1),
          SizedBox(
            height: 200.w,
            width: 200.w,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 180.w,
                  height: 180.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        data.color.withValues(alpha: 0.08),
                        data.color.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 120.w,
                  height: 120.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: data.color.withValues(alpha: 0.1),
                    border: Border.all(
                      color: data.color.withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.gavel_rounded,
                    size: 48.sp,
                    color: data.color,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 48.h),
          Text(
            data.title,
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          Text(
            data.description,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w400,
              color: theme.hintColor,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _OnboardingData {
  final Color color;
  final String title;
  final String description;

  const _OnboardingData({
    required this.color,
    required this.title,
    required this.description,
  });
}
