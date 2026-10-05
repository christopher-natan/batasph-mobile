import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:batasph_mobile/config/language/answer_language.dart';
import 'package:batasph_mobile/config/theme/app_themes.dart';
import 'package:batasph_mobile/pages/settings/settings_controller.dart';

class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({super.key});

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
          const Positioned.fill(child: _SettingsBackdrop()),
          SafeArea(
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 28.h),
                  sliver: SliverList.list(
                    children: [
                      _SettingsHeader(isDark: isDark),
                      SizedBox(height: 18.h),
                      _IntroPanel(isDark: isDark),
                      SizedBox(height: 22.h),
                      _AccountPanel(controller: controller),
                      SizedBox(height: 22.h),
                      _SectionLabel(title: 'Experience'),
                      SizedBox(height: 10.h),
                      Obx(
                        () => _PreferenceCard(
                          isDark: isDark,
                          child: SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 18.w,
                              vertical: 6.h,
                            ),
                            value: controller.isDarkMode.value,
                            onChanged: controller.toggleDarkMode,
                            activeThumbColor: const Color(0xFFA77B43),
                            activeTrackColor: const Color(
                              0xFFA77B43,
                            ).withValues(alpha: 0.35),
                            title: Text(
                              'Dark mode',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF213149),
                              ),
                            ),
                            subtitle: Text(
                              'Switch between parchment light mode and the darker legal-desk look.',
                              style: TextStyle(
                                fontSize: 12.sp,
                                height: 1.55,
                                color: isDark
                                    ? const Color(0xFFA9B4C7)
                                    : const Color(0xFF746E67),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      _PreferenceCard(
                        isDark: isDark,
                        child: Padding(
                          padding: EdgeInsets.all(18.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionCardTitle(
                                title: 'Answer Language',
                                subtitle:
                                    'Choose how BatasPH explains the law after retrieval.',
                                isDark: isDark,
                              ),
                              SizedBox(height: 14.h),
                              Obx(
                                () => Wrap(
                                  spacing: 10.w,
                                  runSpacing: 10.h,
                                  children: AnswerLanguage.values.map((
                                    language,
                                  ) {
                                    final isSelected =
                                        controller.answerLanguage.value ==
                                        language;

                                    return ChoiceChip(
                                      selected: isSelected,
                                      label: Text(language.label),
                                      onSelected: (_) => controller
                                          .changeAnswerLanguage(language),
                                      selectedColor: const Color(0xFF22324D),
                                      backgroundColor: isDark
                                          ? Colors.white.withValues(alpha: 0.06)
                                          : const Color(0xFFF5EBDE),
                                      side: BorderSide(
                                        color: isSelected
                                            ? const Color(0xFF22324D)
                                            : isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.08,
                                              )
                                            : const Color(0xFFE8DCCB),
                                      ),
                                      labelStyle: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? Colors.white
                                            : isDark
                                            ? const Color(0xFFDCE4F0)
                                            : const Color(0xFF33415A),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10.w,
                                        vertical: 10.h,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          999.r,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              SizedBox(height: 12.h),
                              Obx(
                                () => Text(
                                  controller.answerLanguage.value.description,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    height: 1.6,
                                    color: isDark
                                        ? const Color(0xFFA9B4C7)
                                        : const Color(0xFF746E67),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 22.h),
                      _SectionLabel(title: 'Library'),
                      SizedBox(height: 10.h),
                      _PreferenceCard(
                        isDark: isDark,
                        child: Column(
                          children: [
                            Obx(
                              () => _ActionTile(
                                icon: Icons.star_outline_rounded,
                                title: 'Saved Answers',
                                subtitle: controller.savedAnswersCount == 0
                                    ? 'Keep important question-and-answer pairs on this device.'
                                    : '${controller.savedAnswersCount} saved question-and-answer pairs',
                                onTap: controller.openSavedAnswers,
                                isDark: isDark,
                              ),
                            ),
                            _CardDivider(isDark: isDark),
                            _ActionTile(
                              icon: Icons.record_voice_over_outlined,
                              title: 'Voice Settings',
                              subtitle:
                                  'Choose BatasPH voices and speech-transcription languages.',
                              onTap: controller.openVoiceSettings,
                              isDark: isDark,
                            ),
                            _CardDivider(isDark: isDark),
                            Obx(
                              () => _ActionTile(
                                icon: Icons.flag_outlined,
                                title: 'Reported Answers',
                                subtitle: controller.feedbackReportsCount == 0
                                    ? 'Review the answers you already flagged as wrong, missing law, or unclear.'
                                    : '${controller.feedbackReportsCount} answer reports submitted',
                                onTap: controller.openFeedbackReports,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 22.h),
                      _SectionLabel(title: 'Style'),
                      SizedBox(height: 10.h),
                      _PreferenceCard(
                        isDark: isDark,
                        child: Padding(
                          padding: EdgeInsets.all(18.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionCardTitle(
                                title: 'App Theme',
                                subtitle:
                                    'Pick the ink, paper, or archive palette that fits your device.',
                                isDark: isDark,
                              ),
                              SizedBox(height: 14.h),
                              Obx(
                                () => Wrap(
                                  spacing: 10.w,
                                  runSpacing: 10.h,
                                  children: AppThemes.themes.map((themeEntry) {
                                    final isSelected =
                                        controller.currentThemeId.value ==
                                        themeEntry.id.name;

                                    return _ThemeChip(
                                      label: themeEntry.name,
                                      previewColor: isDark
                                          ? themeEntry.previewDark
                                          : themeEntry.previewLight,
                                      isSelected: isSelected,
                                      isDark: isDark,
                                      onTap: () => controller.changeAppTheme(
                                        themeEntry.id,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 22.h),
                      _SectionLabel(title: 'Support'),
                      SizedBox(height: 10.h),
                      _PreferenceCard(
                        isDark: isDark,
                        child: Obx(
                          () => _ActionTile(
                            icon: Icons.bug_report_outlined,
                            title: 'Share Logs',
                            subtitle: controller.isSharingLogs.value
                                ? 'Preparing the latest diagnostic log...'
                                : 'Send the latest diagnostic log to help us track down a problem.',
                            onTap: controller.isSharingLogs.value
                                ? () {}
                                : controller.shareLogs,
                            isDark: isDark,
                          ),
                        ),
                      ),
                      SizedBox(height: 22.h),
                      _SectionLabel(title: 'About'),
                      SizedBox(height: 10.h),
                      _PreferenceCard(
                        isDark: isDark,
                        child: Padding(
                          padding: EdgeInsets.all(18.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionCardTitle(
                                title: 'About BatasPH',
                                subtitle:
                                    'Built to answer Philippine law questions directly while keeping answers grounded, readable, and fast.',
                                isDark: isDark,
                              ),
                              SizedBox(height: 14.h),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 14.w,
                                  vertical: 14.h,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.04)
                                      : const Color(0xFFFFF8EC),
                                  borderRadius: BorderRadius.circular(18.r),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : const Color(0xFFEEE1CF),
                                  ),
                                ),
                                child: Text(
                                  'Answers should stay simple for ordinary people, but still point back to the real law when needed.',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    height: 1.6,
                                    color: isDark
                                        ? const Color(0xFFDCE4F0)
                                        : const Color(0xFF4E5661),
                                  ),
                                ),
                              ),
                            ],
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
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  final bool isDark;

  const _SettingsHeader({required this.isDark});

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
            Icons.tune_rounded,
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
                'Settings',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF24324C),
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'Account, answer style, and voice',
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
      ],
    );
  }
}

class _IntroPanel extends StatelessWidget {
  final bool isDark;

  const _IntroPanel({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(22.w),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF121A25).withValues(alpha: 0.9)
            : const Color(0xFFFBF7F1).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFE7DBCB),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF202A3A,
            ).withValues(alpha: isDark ? 0.16 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color(0xFFFFF8ED),
              borderRadius: BorderRadius.circular(999.r),
            ),
            child: Text(
              'SETTINGS & CONTROLS',
              style: TextStyle(
                color: const Color(0xFFA18867),
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.8,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Shape how BatasPH answers.',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1C2533),
              fontSize: 28.sp,
              fontWeight: FontWeight.w700,
              height: 1.08,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            'Keep your account ready, tune the answer style, and manage saved legal answers without leaving the app’s main experience.',
            style: TextStyle(
              color: isDark ? const Color(0xFFB0BAC9) : const Color(0xFF6E746F),
              fontSize: 13.sp,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountPanel extends StatelessWidget {
  final SettingsController controller;

  const _AccountPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Obx(
      () => Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [
                    Color(0xFF23324A),
                    Color(0xFF192437),
                    Color(0xFF131B28),
                  ]
                : const [
                    Color(0xFF283856),
                    Color(0xFF324866),
                    Color(0xFF1E2A3E),
                  ],
          ),
          borderRadius: BorderRadius.circular(32.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1F2B40).withValues(alpha: 0.18),
              blurRadius: 28,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 54.w,
                  height: 54.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    controller.accountInitials,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.accountName,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        controller.accountSubtitle,
                        style: TextStyle(
                          fontSize: 12.sp,
                          height: 1.45,
                          color: const Color(0xFFD2DDED),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            Text(
              controller.hasAccountSession
                  ? 'Profile screens are active on this device. Server-side sync still depends on BatasPH API auth support.'
                  : 'Account screens are ready. Full sign-in and profile sync still depend on BatasPH API auth endpoints.',
              style: TextStyle(
                fontSize: 12.sp,
                height: 1.55,
                color: const Color(0xFFD2DDED),
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: controller.hasAccountSession
                        ? controller.openProfile
                        : controller.openLogin,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFF22324D),
                      padding: EdgeInsets.symmetric(vertical: 15.h),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.r),
                      ),
                    ),
                    child: Text(
                      controller.hasAccountSession ? 'View profile' : 'Sign in',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: OutlinedButton(
                    onPressed: controller.hasAccountSession
                        ? controller.logout
                        : controller.openRegister,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF24324C),
                      backgroundColor: const Color(0xFFF6F0E3),
                      padding: EdgeInsets.symmetric(vertical: 15.h),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.r),
                      ),
                    ),
                    child: Text(
                      controller.hasAccountSession
                          ? 'Sign out'
                          : 'Create account',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;

  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFA18867),
          letterSpacing: 1.8,
        ),
      ),
    );
  }
}

class _PreferenceCard extends StatelessWidget {
  final bool isDark;
  final Widget child;

  const _PreferenceCard({required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF121A25).withValues(alpha: 0.88)
            : const Color(0xFFFBF7F1).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFE9DECF),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF202A3A,
            ).withValues(alpha: isDark ? 0.14 : 0.07),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionCardTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDark;

  const _SectionCardTitle({
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1F2A3A),
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12.sp,
            height: 1.55,
            color: isDark ? const Color(0xFFA9B4C7) : const Color(0xFF746E67),
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDark;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
          child: Row(
            children: [
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFF3E9DB),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(icon, size: 20.sp, color: const Color(0xFFA77B43)),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1F2A3A),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.sp,
                        height: 1.5,
                        color: isDark
                            ? const Color(0xFFA9B4C7)
                            : const Color(0xFF746E67),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15.sp,
                color: isDark
                    ? const Color(0xFF95A5BE)
                    : const Color(0xFF8A7A67),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardDivider extends StatelessWidget {
  final bool isDark;

  const _CardDivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 74.w),
      child: Divider(
        height: 1,
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFE9DECF),
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  final String label;
  final Color previewColor;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _ThemeChip({
    required this.label,
    required this.previewColor,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.r),
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF22324D)
                : isDark
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFF5EBDE),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF22324D)
                  : isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE8DCCB),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18.w,
                height: 18.w,
                decoration: BoxDecoration(
                  color: previewColor,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? Colors.white
                      : isDark
                      ? const Color(0xFFDCE4F0)
                      : const Color(0xFF33415A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsBackdrop extends StatelessWidget {
  const _SettingsBackdrop();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -120.h,
            right: -80.w,
            child: Container(
              width: 280.w,
              height: 280.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: isDark
                      ? [
                          const Color(0xFF31466A).withValues(alpha: 0.24),
                          Colors.transparent,
                        ]
                      : [
                          const Color(0xFFEEDBB9).withValues(alpha: 0.55),
                          Colors.transparent,
                        ],
                ),
              ),
            ),
          ),
          Positioned(
            left: -70.w,
            top: 180.h,
            child: Container(
              width: 210.w,
              height: 210.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? const Color(0xFF23324A).withValues(alpha: 0.16)
                    : const Color(0xFFE6D2AF).withValues(alpha: 0.28),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
