import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatRecentPromptsComponent extends StatelessWidget {
  final List<String> prompts;
  final VoidCallback onTypeInstead;
  final ValueChanged<String> onSelectPrompt;

  const ChatRecentPromptsComponent({
    super.key,
    required this.prompts,
    required this.onTypeInstead,
    required this.onSelectPrompt,
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
            : const Color(0xFFFBF7F1).withValues(alpha: 0.94),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Prompts',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF1D2737),
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Use a recent question again, or type instead if speaking is not ideal.',
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
                onPressed: onTypeInstead,
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
                icon: const Icon(Icons.keyboard_alt_outlined, size: 18),
                label: Text(
                  'Type Instead',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          if (prompts.isEmpty)
            _EmptyPromptState(isDark: isDark)
          else
            ...prompts.map(
              (prompt) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: _PromptCard(
                  prompt: prompt,
                  onTap: () => onSelectPrompt(prompt),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  final String prompt;
  final VoidCallback onTap;

  const _PromptCard({required this.prompt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                child: Text(
                  prompt,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1E2837),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
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
                  Icons.arrow_upward_rounded,
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
}

class _EmptyPromptState extends StatelessWidget {
  final bool isDark;

  const _EmptyPromptState({required this.isDark});

  @override
  Widget build(BuildContext context) {
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
      child: Text(
        'Your recent spoken or typed questions will appear here after you ask them.',
        style: TextStyle(
          color: isDark ? const Color(0xFFA9B4C7) : const Color(0xFF7B756E),
          fontSize: 13.sp,
          height: 1.55,
        ),
      ),
    );
  }
}
