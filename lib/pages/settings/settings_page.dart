import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:batasph_mobile/config/theme/app_themes.dart';
import 'package:batasph_mobile/pages/settings/settings_controller.dart';

class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 28.h),
          children: [
            _AccountPanel(controller: controller),
            SizedBox(height: 24.h),
            const _SectionLabel(title: 'Call'),
            SizedBox(height: 10.h),
            _Card(
              child: _ActionTile(
                icon: Icons.record_voice_over_outlined,
                title: 'Voice Settings',
                subtitle: 'Choose the languages you speak during a call.',
                onTap: controller.openVoiceSettings,
              ),
            ),
            SizedBox(height: 24.h),
            const _SectionLabel(title: 'Support'),
            SizedBox(height: 10.h),
            _Card(
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
                ),
              ),
            ),
            SizedBox(height: 24.h),
            const _SectionLabel(title: 'About'),
            SizedBox(height: 10.h),
            _Card(
              child: Padding(
                padding: EdgeInsets.all(18.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About BatasPH',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppThemes.ink,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Call Atty. Luna, BatasPH\'s AI legal guide, to ask about Philippine law in English or Tagalog. Every answer points back to the law it is based on.',
                      style: TextStyle(
                        fontSize: 13.sp,
                        height: 1.55,
                        color: AppThemes.muted,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'General legal information, not legal advice.',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: AppThemes.forest,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountPanel extends StatelessWidget {
  final SettingsController controller;

  const _AccountPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => _Card(
        child: Padding(
          padding: EdgeInsets.all(18.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52.w,
                    height: 52.w,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppThemes.forest,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      controller.accountInitials,
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w600,
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
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: AppThemes.ink,
                          ),
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          controller.accountSubtitle,
                          style: TextStyle(
                            fontSize: 12.sp,
                            height: 1.45,
                            color: AppThemes.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: controller.hasAccountSession
                          ? controller.openProfile
                          : controller.openLogin,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppThemes.forest,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999.r),
                        ),
                      ),
                      child: Text(
                        controller.hasAccountSession
                            ? 'View profile'
                            : 'Sign in',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
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
                        foregroundColor: AppThemes.ink,
                        backgroundColor: AppThemes.surfaceSoft,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999.r),
                        ),
                      ),
                      child: Text(
                        controller.hasAccountSession
                            ? 'Sign out'
                            : 'Create account',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
          fontWeight: FontWeight.w600,
          color: AppThemes.muted,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppThemes.line),
      ),
      child: child,
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
          child: Row(
            children: [
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  color: AppThemes.forest.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(icon, size: 20.sp, color: AppThemes.forest),
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
                        fontWeight: FontWeight.w600,
                        color: AppThemes.ink,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.sp,
                        height: 1.5,
                        color: AppThemes.muted,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15.sp,
                color: AppThemes.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
