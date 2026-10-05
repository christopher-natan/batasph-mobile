// ignore_for_file: constant_identifier_names
import 'package:get/get.dart';
import 'package:batasph_mobile/pages/feedback_reports/feedback_reports_binding.dart';
import 'package:batasph_mobile/pages/feedback_reports/feedback_reports_page.dart';
import 'package:batasph_mobile/pages/forgot_password/forgot_password_binding.dart';
import 'package:batasph_mobile/pages/forgot_password/forgot_password_page.dart';
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
import 'package:batasph_mobile/pages/report_answer/report_answer_binding.dart';
import 'package:batasph_mobile/pages/report_answer/report_answer_page.dart';
import 'package:batasph_mobile/pages/register/register_binding.dart';
import 'package:batasph_mobile/pages/register/register_page.dart';
import 'package:batasph_mobile/pages/saved_answers/saved_answers_binding.dart';
import 'package:batasph_mobile/pages/saved_answers/saved_answers_page.dart';
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
      name: _Paths.REPORT_ANSWER,
      page: () => const ReportAnswerPage(),
      binding: ReportAnswerBinding(),
    ),
    GetPage(
      name: _Paths.SAVED_ANSWERS,
      page: () => const SavedAnswersPage(),
      binding: SavedAnswersBinding(),
    ),
    GetPage(
      name: _Paths.FEEDBACK_REPORTS,
      page: () => const FeedbackReportsPage(),
      binding: FeedbackReportsBinding(),
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
