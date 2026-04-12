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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
        children: [
          Obx(
            () => Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24.r,
                          child: Text(
                            controller.accountInitials,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                controller.accountName,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                controller.accountSubtitle,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: theme.hintColor,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      controller.hasAccountSession
                          ? 'Profile screens are active on this device. Server-side sync depends on BatasPH API auth support.'
                          : 'Account screens are ready. Full sign-in and profile sync require BatasPH API auth endpoints.',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: theme.hintColor,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    if (controller.hasAccountSession) ...[
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: controller.openProfile,
                              child: const Text('View profile'),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: controller.logout,
                              child: const Text('Sign out'),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: controller.openLogin,
                              child: const Text('Sign in'),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: controller.openRegister,
                              child: const Text('Create account'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Obx(
            () => Card(
              child: SwitchListTile(
                value: controller.isDarkMode.value,
                onChanged: controller.toggleDarkMode,
                title: const Text('Dark mode'),
                subtitle: const Text('Switch between light and dark themes'),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Answer Language',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Choose how BatasPH should explain retrieved law text.',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: theme.hintColor,
                      height: 1.6,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Obx(
                    () => Wrap(
                      spacing: 10.w,
                      runSpacing: 10.h,
                      children: AnswerLanguage.values.map((language) {
                        final isSelected =
                            controller.answerLanguage.value == language;
                        return ChoiceChip(
                          selected: isSelected,
                          label: Text(language.label),
                          onSelected: (_) =>
                              controller.changeAnswerLanguage(language),
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Obx(
                    () => Text(
                      controller.answerLanguage.value.description,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: theme.hintColor,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Card(
            child: ListTile(
              leading: const Icon(Icons.record_voice_over_outlined),
              title: const Text('Voice Settings'),
              subtitle: const Text(
                'Choose BatasPH stream voices and speech-transcription languages.',
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: controller.openVoiceSettings,
            ),
          ),
          SizedBox(height: 16.h),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'App Theme',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Obx(
                    () => Wrap(
                      spacing: 10.w,
                      runSpacing: 10.h,
                      children: AppThemes.themes.map((themeEntry) {
                        final isSelected =
                            controller.currentThemeId.value ==
                            themeEntry.id.name;
                        return ChoiceChip(
                          selected: isSelected,
                          label: Text(themeEntry.name),
                          onSelected: (_) =>
                              controller.changeAppTheme(themeEntry.id),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About BatasPH',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'BatasPH is being structured as a source-first Philippine law assistant. Answers should be grounded in raw law text with citations and a clear disclaimer.',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: theme.hintColor,
                      height: 1.6,
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
