import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:batasph_mobile/config/language/answer_language.dart';
import 'package:batasph_mobile/pages/home/models/starter_question_model.dart';

class HomeStarterQuestionsComponent extends StatelessWidget {
  final List<StarterQuestionModel> questions;
  final AnswerLanguage answerLanguage;
  final bool isLoading;
  final String errorMessage;
  final VoidCallback onRefresh;
  final VoidCallback onRetry;
  final ValueChanged<StarterQuestionModel> onTapQuestion;

  const HomeStarterQuestionsComponent({
    super.key,
    required this.questions,
    required this.answerLanguage,
    required this.isLoading,
    required this.errorMessage,
    required this.onRefresh,
    required this.onRetry,
    required this.onTapQuestion,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF121A25).withValues(alpha: 0.88)
            : const Color(0xFFFBF7F1).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFE9DECF),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF202A3A,
            ).withValues(alpha: isDark ? 0.18 : 0.08),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Starter Questions',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF1D2737),
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Fresh prompts from the database, matched to your app language.',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFA9B4C7)
                            : const Color(0xFF7B756E),
                        fontSize: 12.sp,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              TextButton.icon(
                onPressed: onRefresh,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF43506B),
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFE9DFD0),
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 10.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                ),
                icon: const Icon(Icons.shuffle_rounded, size: 18),
                label: Text(
                  'Refresh',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          if (isLoading && questions.isEmpty) ...[
            const _StarterQuestionsLoading(),
          ] else if (errorMessage.isNotEmpty && questions.isEmpty) ...[
            _StarterQuestionsError(message: errorMessage, onRetry: onRetry),
          ] else ...[
            ...questions.map(
              (question) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: _StarterQuestionCard(
                  question: question,
                  answerLanguage: answerLanguage,
                  onTap: () => onTapQuestion(question),
                ),
              ),
            ),
            if (isLoading)
              Padding(
                padding: EdgeInsets.only(top: 4.h),
                child: Row(
                  children: [
                    SizedBox(
                      width: 14.w,
                      height: 14.w,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      'Refreshing questions...',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFA9B4C7)
                            : const Color(0xFF7B756E),
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _StarterQuestionCard extends StatelessWidget {
  final StarterQuestionModel question;
  final AnswerLanguage answerLanguage;
  final VoidCallback onTap;

  const _StarterQuestionCard({
    required this.question,
    required this.answerLanguage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subjectLabel = _subjectLabel(question.subjects);
    final subjectColors = _subjectColors(subjectLabel, isDark);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24.r),
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 18.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF17202C) : Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFF1E9DD),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: subjectColors.$1,
                        borderRadius: BorderRadius.circular(999.r),
                      ),
                      child: Text(
                        subjectLabel,
                        style: TextStyle(
                          color: subjectColors.$2,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      question.textFor(answerLanguage),
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF1E2837),
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 14.w),
              Container(
                width: 38.w,
                height: 38.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? const Color(0xFF2B3546)
                      : const Color(0xFFF4EBDE),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: const Color(0xFFA77B43),
                  size: 20.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _subjectLabel(List<String> subjects) {
    if (subjects.any((subject) => subject == 'constitution')) {
      return 'Constitution';
    }
    if (subjects.any((subject) => subject == 'traffic_law')) {
      return 'Traffic';
    }
    if (subjects.any((subject) => subject == 'workers_rights')) {
      return 'Workers\' Rights';
    }
    return 'Law';
  }

  (Color, Color) _subjectColors(String label, bool isDark) {
    switch (label) {
      case 'Constitution':
        return (
          isDark ? const Color(0xFF24334D) : const Color(0xFFEFF1F6),
          isDark ? const Color(0xFFC9D5EC) : const Color(0xFF4D607F),
        );
      case 'Traffic':
        return (
          isDark ? const Color(0xFF17372F) : const Color(0xFFEDF5F2),
          isDark ? const Color(0xFFB7E0D2) : const Color(0xFF2E7768),
        );
      case 'Workers\' Rights':
        return (
          isDark ? const Color(0xFF372B24) : const Color(0xFFF3EEE8),
          isDark ? const Color(0xFFE1C5B4) : const Color(0xFF83543C),
        );
      default:
        return (
          isDark ? const Color(0xFF2B3546) : const Color(0xFFF1ECE3),
          isDark ? const Color(0xFFC5CFDF) : const Color(0xFF5B6270),
        );
    }
  }
}

class _StarterQuestionsLoading extends StatelessWidget {
  const _StarterQuestionsLoading();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF17202C) : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFF1E9DD),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18.w,
            height: 18.w,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'Loading dynamic starter questions...',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1E2837),
                fontSize: 13.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StarterQuestionsError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _StarterQuestionsError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF17202C) : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFF1E9DD),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: TextStyle(
              color: theme.colorScheme.error,
              fontSize: 13.sp,
              height: 1.5,
            ),
          ),
          SizedBox(height: 12.h),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
