import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:batasph_mobile/pages/home/components/home_backdrop_component.dart';
import 'package:batasph_mobile/pages/home/components/home_hero_component.dart';
import 'package:batasph_mobile/pages/home/components/home_starter_questions_component.dart';
import 'package:batasph_mobile/pages/home/home_controller.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF10141B)
          : const Color(0xFFF7F2E8),
      body: Stack(
        children: [
          const Positioned.fill(child: HomeBackdropComponent()),
          SafeArea(
            child: RefreshIndicator(
              color: const Color(0xFF22324D),
              onRefresh: controller.loadStarterQuestions,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 28.h),
                    sliver: SliverList.list(
                      children: [
                        _HomeHeader(
                          isDark: isDark,
                          onOpenSavedAnswers: controller.openSavedAnswers,
                        ),
                        SizedBox(height: 18.h),
                        _IntroBlock(isDark: isDark),
                        SizedBox(height: 22.h),
                        HomeHeroComponent(
                          quickSubjects: controller.quickSubjects,
                          onOpenTextChat: controller.openAskBatas,
                          onOpenVoiceChat: controller.openVoiceChat,
                        ),
                        SizedBox(height: 22.h),
                        Obx(
                          () => HomeStarterQuestionsComponent(
                            questions: controller.starterQuestions,
                            answerLanguage: controller.answerLanguage.value,
                            isLoading:
                                controller.isLoadingStarterQuestions.value,
                            errorMessage:
                                controller.starterQuestionsError.value,
                            onRefresh: controller.loadStarterQuestions,
                            onRetry: controller.loadStarterQuestions,
                            onTapQuestion: (question) =>
                                controller.openAskBatas(
                                  question.textFor(
                                    controller.answerLanguage.value,
                                  ),
                                ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        _DesignNote(isDark: isDark),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final bool isDark;
  final VoidCallback onOpenSavedAnswers;

  const _HomeHeader({required this.isDark, required this.onOpenSavedAnswers});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42.w,
          height: 42.w,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C2533) : const Color(0xFFFDF8EF),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color(0xFFE8DDCD),
            ),
          ),
          child: Icon(
            Icons.gavel_rounded,
            color: const Color(0xFFA77B43),
            size: 20.sp,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BatasPH',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF24324C),
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'Source-first legal assistant',
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFFAAB5C7)
                      : const Color(0xFF8A7A67),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 12.w),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onOpenSavedAnswers,
            borderRadius: BorderRadius.circular(16.r),
            child: Container(
              width: 42.w,
              height: 42.w,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1C2533)
                    : const Color(0xFFFDF8EF),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : const Color(0xFFE8DDCD),
                ),
              ),
              child: Icon(
                Icons.star_outline_rounded,
                color: const Color(0xFFA77B43),
                size: 20.sp,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _IntroBlock extends StatelessWidget {
  final bool isDark;

  const _IntroBlock({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFFFF8ED).withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(999.r),
          ),
          child: Text(
            'SOURCE-FIRST LEGAL ASSISTANT',
            style: TextStyle(
              color: const Color(0xFFA18867),
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.9,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          'Ask with clarity.',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1C2533),
            fontSize: 30.sp,
            fontWeight: FontWeight.w700,
            height: 1.05,
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          'Law-grounded answers in plain English or Filipino, streamed fast and backed by legal basis.',
          style: TextStyle(
            color: isDark ? const Color(0xFFB0BAC9) : const Color(0xFF6E746F),
            fontSize: 14.sp,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class _DesignNote extends StatelessWidget {
  final bool isDark;

  const _DesignNote({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFECE1D2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WHY THIS DIRECTION',
            style: TextStyle(
              color: const Color(0xFFA18867),
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            'The redesign treats BatasPH like a legal desk: warm paper tones, sharper hierarchy, quieter cards, and stronger trust cues.',
            style: TextStyle(
              color: isDark ? const Color(0xFFB0BAC9) : const Color(0xFF59606B),
              fontSize: 13.sp,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
