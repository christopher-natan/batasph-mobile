import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeHeroComponent extends StatelessWidget {
  final List<String> quickSubjects;
  final VoidCallback onOpenTextChat;
  final VoidCallback onOpenVoiceChat;

  const HomeHeroComponent({
    super.key,
    required this.quickSubjects,
    required this.onOpenTextChat,
    required this.onOpenVoiceChat,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(32.r),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [
                    Color(0xFF213149),
                    Color(0xFF192437),
                    Color(0xFF141C2A),
                  ]
                : const [
                    Color(0xFF283856),
                    Color(0xFF334868),
                    Color(0xFF1E2A3E),
                  ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1F2B40).withValues(alpha: 0.18),
              blurRadius: 28,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -36,
              right: -28,
              child: Container(
                width: 168.w,
                height: 168.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF7E5C5).withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(top: 18.h, right: 22.w, child: const _BalanceSeal()),
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 22.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 7.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999.r),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Text(
                      'TODAY\'S LEGAL START',
                      style: TextStyle(
                        color: const Color(0xFFF3D6A4),
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.8,
                      ),
                    ),
                  ),
                  SizedBox(height: 18.h),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 250.w),
                    child: Text(
                      'Ask Philippine law with confidence.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w700,
                        height: 1.12,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 280.w),
                    child: Text(
                      'Fast streamed answers, official-source grounding, and a guided path into your next question.',
                      style: TextStyle(
                        color: const Color(0xFFD4DDED),
                        fontSize: 13.sp,
                        height: 1.6,
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Wrap(
                    spacing: 10.w,
                    runSpacing: 12.h,
                    children: quickSubjects
                        .map(
                          (subject) => Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 10.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999.r),
                            ),
                            child: Text(
                              subject,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  SizedBox(height: 22.h),
                  Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24.r),
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xFFC18B47), Color(0xFFE2BF85)],
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: onOpenTextChat,
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: const Color(0xFF22324D),
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18.r),
                              ),
                            ),
                            child: Text(
                              'Text Chat',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: onOpenVoiceChat,
                            style: ElevatedButton.styleFrom(
                              foregroundColor: const Color(0xFF28344E),
                              backgroundColor: const Color(0xFFF6F0E3),
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18.r),
                              ),
                            ),
                            child: Text(
                              'Voice Chat',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceSeal extends StatelessWidget {
  const _BalanceSeal();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84.w,
      height: 84.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF7E5C5).withValues(alpha: 0.08),
        border: Border.all(
          color: const Color(0xFFE1BA7A).withValues(alpha: 0.24),
        ),
      ),
      child: Icon(
        Icons.balance_rounded,
        color: const Color(0xFFE8C38A),
        size: 34.sp,
      ),
    );
  }
}
