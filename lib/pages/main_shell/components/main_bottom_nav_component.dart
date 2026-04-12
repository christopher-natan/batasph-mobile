import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MainBottomNavComponent extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const MainBottomNavComponent({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      minimum: EdgeInsets.fromLTRB(18.w, 0, 18.w, 10.h),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 7.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF182232).withValues(alpha: 0.54),
                        const Color(0xFF121A25).withValues(alpha: 0.46),
                      ]
                    : [
                        const Color(0xFFFFFCF5).withValues(alpha: 0.56),
                        const Color(0xFFF3EBDC).withValues(alpha: 0.44),
                      ],
              ),
              borderRadius: BorderRadius.circular(28.r),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : const Color(0xFFF6EFE3).withValues(alpha: 0.6),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(
                    0xFF1E2837,
                  ).withValues(alpha: isDark ? 0.1 : 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                _MainBottomNavItem(
                  label: 'Home',
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  isSelected: currentIndex == 0,
                  onTap: () => onTap(0),
                ),
                _MainBottomNavItem(
                  label: 'Ask',
                  icon: Icons.question_answer_outlined,
                  activeIcon: Icons.question_answer_rounded,
                  isSelected: currentIndex == 1,
                  onTap: () => onTap(1),
                  isPrimary: true,
                ),
                _MainBottomNavItem(
                  label: 'Sources',
                  icon: Icons.menu_book_outlined,
                  activeIcon: Icons.menu_book_rounded,
                  isSelected: currentIndex == 2,
                  onTap: () => onTap(2),
                ),
                _MainBottomNavItem(
                  label: 'Settings',
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings_rounded,
                  isSelected: currentIndex == 3,
                  onTap: () => onTap(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MainBottomNavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool isSelected;
  final bool isPrimary;
  final VoidCallback onTap;

  const _MainBottomNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.isSelected,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeBackground = isDark
        ? const Color(0xFF24334D)
        : const Color(0xFF283856);
    final activeTextColor = Colors.white;
    final inactiveTextColor = isDark
        ? const Color(0xFFA8B3C6)
        : const Color(0xFF6E746F);
    final inactiveIconColor = isDark
        ? const Color(0xFF9EABC0)
        : const Color(0xFF6E746F);

    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 3.w),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20.r),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                gradient: isSelected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isPrimary
                            ? const [Color(0xFF22324D), Color(0xFF334868)]
                            : [
                                activeBackground.withValues(alpha: 0.94),
                                activeBackground.withValues(alpha: 0.84),
                              ],
                      )
                    : null,
                color: isSelected
                    ? null
                    : isPrimary
                    ? (isDark
                          ? const Color(0xFFE2BF85).withValues(alpha: 0.08)
                          : const Color(0xFFC18B47).withValues(alpha: 0.08))
                    : Colors.transparent,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: isSelected ? 30.w : 28.w,
                    height: isSelected ? 30.w : 28.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.12)
                          : isPrimary
                          ? (isDark
                                ? const Color(
                                    0xFFE2BF85,
                                  ).withValues(alpha: 0.12)
                                : const Color(
                                    0xFFC18B47,
                                  ).withValues(alpha: 0.12))
                          : Colors.transparent,
                    ),
                    child: Icon(
                      isSelected ? activeIcon : icon,
                      color: isSelected ? activeTextColor : inactiveIconColor,
                      size: 19.sp,
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? activeTextColor : inactiveTextColor,
                      fontSize: 10.5.sp,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: isSelected ? 16.w : 4.w,
                    height: 2.5.h,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFE2BF85)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(999.r),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
