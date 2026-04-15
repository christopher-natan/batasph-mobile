import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:batasph_mobile/pages/chat/chat_controller.dart';
import 'package:batasph_mobile/pages/chat/chat_page.dart';
import 'package:batasph_mobile/pages/home/home_page.dart';
import 'package:batasph_mobile/pages/main_shell/components/main_bottom_nav_component.dart';
import 'package:batasph_mobile/pages/main_shell/main_shell_controller.dart';
import 'package:batasph_mobile/pages/settings/settings_page.dart';

class MainShellPage extends GetView<MainShellController> {
  const MainShellPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Obx(() {
      final currentIndex = controller.currentTabIndex.value;
      final loadedTabIndexes = Set<int>.from(controller.loadedTabIndexes);
      final shouldHideBottomNav =
          currentIndex == 1 &&
          loadedTabIndexes.contains(1) &&
          Get.find<ChatController>().isTextChatMode.value;

      return Scaffold(
        backgroundColor: _backgroundColorForTab(
          index: currentIndex,
          isDark: isDark,
          fallback: theme.scaffoldBackgroundColor,
        ),
        body: IndexedStack(
          index: currentIndex,
          children: [
            loadedTabIndexes.contains(0)
                ? const HomePage()
                : const SizedBox.shrink(),
            loadedTabIndexes.contains(1)
                ? const ChatPage()
                : const SizedBox.shrink(),
            loadedTabIndexes.contains(2)
                ? const SettingsPage()
                : const SizedBox.shrink(),
          ],
        ),
        bottomNavigationBar: shouldHideBottomNav
            ? null
            : MainBottomNavComponent(
                currentIndex: currentIndex,
                onTap: controller.changeTab,
              ),
      );
    });
  }

  Color _backgroundColorForTab({
    required int index,
    required bool isDark,
    required Color fallback,
  }) {
    if (index == 0) {
      return isDark ? const Color(0xFF10141B) : const Color(0xFFF7F2E8);
    }
    return fallback;
  }
}
