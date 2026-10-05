import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:batasph_mobile/components/brand_logo_component.dart';
import 'package:batasph_mobile/components/call_screen_frame_component.dart';
import 'package:batasph_mobile/components/circular_call_button_component.dart';
import 'package:batasph_mobile/components/persona_avatar_component.dart';
import 'package:batasph_mobile/config/config.dart';
import 'package:batasph_mobile/config/theme/app_themes.dart';
import 'package:batasph_mobile/pages/home/home_controller.dart';

/// A familiar dialer: one button to call Luna, who answers in Taglish.
class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CallScreenFrameComponent(
        child: Column(
          children: [
            Row(
              children: [
                const BrandLogoComponent(),
                const Spacer(),
                IconButton(
                  onPressed: controller.openSettings,
                  tooltip: 'Settings',
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: AppThemes.forest,
                    size: 24,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const SizedBox(height: 28),
            const Text(
              'YOUR AI LEGAL GUIDE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 2.5,
                color: AppThemes.forest,
              ),
            ),
            const SizedBox(height: 24),
            const PersonaAvatarComponent(size: 238),
            const SizedBox(height: 20),
            const Text(
              AppConfig.personaName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 34,
                height: 1.15,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
                color: AppThemes.forest,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Philippine law, made clearer.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppThemes.forest),
            ),
            const Spacer(),
            const SizedBox(height: 26),
            CircularCallButtonComponent(
              label: 'Call ${AppConfig.personaName}',
              onTap: controller.startCall,
            ),
            const SizedBox(height: 4),
            const Text(
              'Ask your question out loud',
              style: TextStyle(fontSize: 12, color: AppThemes.muted),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
