// ignore_for_file: constant_identifier_names
import 'package:get/get.dart';
import 'package:batasph_mobile/pages/login/login_binding.dart';
import 'package:batasph_mobile/pages/login/login_page.dart';
import 'package:batasph_mobile/pages/legal_webview/legal_webview_binding.dart';
import 'package:batasph_mobile/pages/legal_webview/legal_webview_page.dart';
import 'package:batasph_mobile/pages/main_shell/main_shell_binding.dart';
import 'package:batasph_mobile/pages/main_shell/main_shell_page.dart';
import 'package:batasph_mobile/pages/onboarding/onboarding_binding.dart';
import 'package:batasph_mobile/pages/onboarding/onboarding_page.dart';
import 'package:batasph_mobile/pages/profile/profile_binding.dart';
import 'package:batasph_mobile/pages/profile/profile_page.dart';
import 'package:batasph_mobile/pages/register/register_binding.dart';
import 'package:batasph_mobile/pages/register/register_page.dart';
import 'package:batasph_mobile/pages/splash/splash_binding.dart';
import 'package:batasph_mobile/pages/splash/splash_page.dart';
import 'package:batasph_mobile/pages/voice_chat/voice_chat_binding.dart';
import 'package:batasph_mobile/pages/voice_chat/voice_chat_page.dart';
import 'package:batasph_mobile/pages/voice_settings/voice_settings_binding.dart';
import 'package:batasph_mobile/pages/voice_settings/voice_settings_page.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(
      name: _Paths.SPLASH,
      page: () => const SplashPage(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: _Paths.ONBOARDING,
      page: () => const OnboardingPage(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: _Paths.LOGIN,
      page: () => const LoginPage(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: _Paths.REGISTER,
      page: () => const RegisterPage(),
      binding: RegisterBinding(),
    ),
    GetPage(
      name: _Paths.MAIN_SHELL,
      page: () => const MainShellPage(),
      binding: MainShellBinding(),
    ),
    GetPage(
      name: _Paths.LEGAL_WEBVIEW,
      page: () => const LegalWebViewPage(),
      binding: LegalWebViewBinding(),
    ),
    GetPage(
      name: _Paths.PROFILE,
      page: () => const ProfilePage(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: _Paths.VOICE_CHAT,
      page: () => const VoiceChatPage(),
      binding: VoiceChatBinding(),
    ),
    GetPage(
      name: _Paths.VOICE_SETTINGS,
      page: () => const VoiceSettingsPage(),
      binding: VoiceSettingsBinding(),
    ),
  ];
}
