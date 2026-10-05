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
      minimum: EdgeInsets.fromLTRB(18.w, 0, 18.w, 12.h),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.w),
        child: Row(
          children: [
            _SideNavItem(
              label: 'Home',
              icon: Icons.home_outlined,
              selectedIcon: Icons.home_rounded,
              isSelected: currentIndex == 0,
              isDark: isDark,
              onTap: () => onTap(0),
            ),
            SizedBox(width: 8.w),
            _VoiceChatNavItem(
              isSelected: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            SizedBox(width: 8.w),
            _SideNavItem(
              label: 'Settings',
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings_rounded,
              isSelected: currentIndex == 2,
              isDark: isDark,
              onTap: () => onTap(2),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideNavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _SideNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedColor = isDark
        ? const Color(0xFFF2D8AA)
        : const Color(0xFF24334D);
    final idleColor = isDark
        ? const Color(0xFF9DAFC5)
        : const Color(0xFF757B80);

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22.r),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 66.h,
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark
                          ? const Color(0xFF29384B)
                          : const Color(0xFFF4EADB))
                    : (isDark
                          ? const Color(0xFF192434)
                          : const Color(0xFFFFFBF4)),
                borderRadius: BorderRadius.circular(22.r),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF344157)
                      : const Color(0xFFE8DDCB),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF152238).withValues(
                      alpha: isDark ? 0.28 : 0.10,
                    ),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isSelected ? selectedIcon : icon,
                    color: isSelected ? selectedColor : idleColor,
                    size: 23.sp,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      color: isSelected ? selectedColor : idleColor,
                      fontSize: 11.sp,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
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

class _VoiceChatNavItem extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _VoiceChatNavItem({required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: 'Voice and Chat',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22.r),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 66.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isSelected
                      ? const [Color(0xFFC18B47), Color(0xFFE2BF85)]
                      : const [Color(0xFF22324B), Color(0xFF2D405D)],
                ),
                borderRadius: BorderRadius.circular(22.r),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFF3DCB4)
                      : const Color(0xFF435270),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF152238).withValues(alpha: 0.2),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.mic_rounded,
                        color: isSelected
                            ? const Color(0xFF22324B)
                            : const Color(0xFFF1D5A5),
                        size: 21.sp,
                      ),
                      SizedBox(width: 4.w),
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: isSelected
                            ? const Color(0xFF22324B)
                            : Colors.white,
                        size: 18.sp,
                      ),
                    ],
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    'Voice & Chat',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF22324B)
                          : Colors.white,
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w700,
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
