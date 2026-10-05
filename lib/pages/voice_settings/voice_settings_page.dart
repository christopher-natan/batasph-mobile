import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:batasph_mobile/pages/voice_settings/voice_settings_controller.dart';
import 'package:batasph_mobile/utils/voice_avatar_util.dart';

class VoiceSettingsPage extends GetView<VoiceSettingsController> {
  const VoiceSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Voice Settings',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        bottom: true,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
          children: [
            _SectionLabel(title: 'Select Voice'),
            SizedBox(height: 8.h),
            _VoiceGroup(
              theme: theme,
              title: 'Female',
              voices: VoiceSettingsController.voices
                  .where((voice) => voice['gender'] == 'female')
                  .toList(),
            ),
            SizedBox(height: 16.h),
            _VoiceGroup(
              theme: theme,
              title: 'Male',
              voices: VoiceSettingsController.voices
                  .where((voice) => voice['gender'] == 'male')
                  .toList(),
            ),
            SizedBox(height: 28.h),
            _SectionLabel(title: 'Speech Languages'),
            SizedBox(height: 6.h),
            Text(
              'Voice chat uploads recorded audio for transcription. Keep English selected and add Tagalog or another language if you speak in a mix.',
              style: TextStyle(
                fontSize: 12.sp,
                color: theme.hintColor,
                height: 1.4,
              ),
            ),
            SizedBox(height: 10.h),
            Obx(
              () => _SettingsCard(
                children: VoiceSettingsController.supportedLanguages
                    .asMap()
                    .entries
                    .map((entry) {
                      final index = entry.key;
                      final language = entry.value;
                      final code = language['code']!;
                      final isLocked = code == 'en';
                      final isSelected = controller.speechLanguages.contains(
                        code,
                      );

                      return Column(
                        children: [
                          if (index > 0) _SettingsDivider(theme: theme),
                          _SettingsRow(
                            icon: Icons.language_rounded,
                            label: language['label']!,
                            isSelected: isSelected,
                            locked: isLocked,
                            onTap: isLocked
                                ? null
                                : () => controller.toggleSpeechLanguage(code),
                          ),
                        ],
                      );
                    })
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceGroup extends GetView<VoiceSettingsController> {
  final ThemeData theme;
  final String title;
  final List<Map<String, String>> voices;

  const _VoiceGroup({
    required this.theme,
    required this.title,
    required this.voices,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: theme.hintColor,
            ),
          ),
        ),
        SizedBox(height: 6.h),
        Obx(
          () => _SettingsCard(
            children: voices.asMap().entries.map((entry) {
              final index = entry.key;
              final voice = entry.value;
              final isSelected = controller.selectedVoice.value == voice['id'];

              return Column(
                children: [
                  if (index > 0) _SettingsDivider(theme: theme),
                  _SettingsRow(
                    icon: Icons.mic_rounded,
                    label: voice['label']!,
                    avatarAsset: VoiceAvatarUtil.assetFor(voice['id']!),
                    avatarFallbackColor: VoiceAvatarUtil.fallbackColorFor(
                      voice['id']!,
                    ),
                    isSelected: isSelected,
                    onTap: isSelected
                        ? null
                        : () => controller.setSelectedVoice(voice['id']!),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
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
          color: Theme.of(context).hintColor,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  final ThemeData theme;

  const _SettingsDivider({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 56.w),
      child: Divider(
        height: 1,
        color: theme.dividerColor.withValues(alpha: 0.1),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? avatarAsset;
  final Color? avatarFallbackColor;
  final bool isSelected;
  final bool locked;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    this.avatarAsset,
    this.avatarFallbackColor,
    required this.isSelected,
    this.locked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Row(
          children: [
            _LeadingVisual(
              icon: icon,
              avatarAsset: avatarAsset,
              avatarFallbackColor: avatarFallbackColor,
              isSelected: isSelected,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? theme.colorScheme.primary : null,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                locked ? Icons.lock_rounded : Icons.check_circle_rounded,
                color: theme.colorScheme.primary,
                size: 20.sp,
              ),
          ],
        ),
      ),
    );
  }
}

class _LeadingVisual extends StatelessWidget {
  final IconData icon;
  final String? avatarAsset;
  final Color? avatarFallbackColor;
  final bool isSelected;

  const _LeadingVisual({
    required this.icon,
    required this.avatarAsset,
    required this.avatarFallbackColor,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 40.w,
      height: 40.w,
      decoration: BoxDecoration(
        color: avatarAsset == null
            ? (isSelected ? theme.colorScheme.primary : theme.hintColor)
                  .withValues(alpha: 0.12)
            : null,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.26)
              : theme.dividerColor.withValues(alpha: 0.12),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: avatarAsset != null
          ? Image.asset(
              avatarAsset!,
              fit: BoxFit.cover,
              cacheWidth: 160,
              errorBuilder: (_, _, _) => _AvatarFallback(
                color:
                    avatarFallbackColor ??
                    theme.colorScheme.primary.withValues(alpha: 0.8),
                icon: icon,
              ),
            )
          : _AvatarFallback(
              color:
                  avatarFallbackColor ??
                  (isSelected ? theme.colorScheme.primary : theme.hintColor),
              icon: icon,
            ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _AvatarFallback({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withValues(alpha: 0.18),
      alignment: Alignment.center,
      child: Icon(icon, size: 18.sp, color: color),
    );
  }
}
