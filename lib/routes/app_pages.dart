// ignore_for_file: constant_identifier_names
import 'package:get/get.dart';
import 'package:batasph_mobile/pages/forgot_password/forgot_password_binding.dart';
import 'package:batasph_mobile/pages/forgot_password/forgot_password_page.dart';
import 'package:batasph_mobile/pages/home/home_binding.dart';
import 'package:batasph_mobile/pages/home/home_page.dart';
import 'package:batasph_mobile/pages/login/login_binding.dart';
import 'package:batasph_mobile/pages/login/login_page.dart';
import 'package:batasph_mobile/pages/onboarding/onboarding_binding.dart';
import 'package:batasph_mobile/pages/onboarding/onboarding_page.dart';
import 'package:batasph_mobile/pages/profile/profile_binding.dart';
import 'package:batasph_mobile/pages/profile/profile_page.dart';
import 'package:batasph_mobile/pages/register/register_binding.dart';
import 'package:batasph_mobile/pages/register/register_page.dart';
import 'package:batasph_mobile/pages/settings/settings_binding.dart';
import 'package:batasph_mobile/pages/settings/settings_page.dart';
import 'package:batasph_mobile/pages/splash/splash_binding.dart';
import 'package:batasph_mobile/pages/splash/splash_page.dart';
import 'package:batasph_mobile/pages/verify_email/verify_email_binding.dart';
import 'package:batasph_mobile/pages/verify_email/verify_email_page.dart';
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
      name: _Paths.VERIFY_EMAIL,
      page: () => const VerifyEmailPage(),
      binding: VerifyEmailBinding(),
    ),
    GetPage(
      name: _Paths.FORGOT_PASSWORD,
      page: () => const ForgotPasswordPage(),
      binding: ForgotPasswordBinding(),
    ),
    GetPage(
      name: _Paths.HOME,
      page: () => const HomePage(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.SETTINGS,
      page: () => const SettingsPage(),
      binding: SettingsBinding(),
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
