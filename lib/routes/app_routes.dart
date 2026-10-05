// ignore_for_file: constant_identifier_names
part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  static const SPLASH = _Paths.SPLASH;
  static const ONBOARDING = _Paths.ONBOARDING;
  static const LOGIN = _Paths.LOGIN;
  static const REGISTER = _Paths.REGISTER;
  static const VERIFY_EMAIL = _Paths.VERIFY_EMAIL;
  static const FORGOT_PASSWORD = _Paths.FORGOT_PASSWORD;
  static const MAIN_SHELL = _Paths.MAIN_SHELL;
  static const LEGAL_WEBVIEW = _Paths.LEGAL_WEBVIEW;
  static const PROFILE = _Paths.PROFILE;
  static const REPORT_ANSWER = _Paths.REPORT_ANSWER;
  static const SAVED_ANSWERS = _Paths.SAVED_ANSWERS;
  static const FEEDBACK_REPORTS = _Paths.FEEDBACK_REPORTS;
  static const VOICE_CHAT = _Paths.VOICE_CHAT;
  static const VOICE_SETTINGS = _Paths.VOICE_SETTINGS;
}

abstract class _Paths {
  _Paths._();
  static const SPLASH = '/splash';
  static const ONBOARDING = '/onboarding';
  static const LOGIN = '/login';
  static const REGISTER = '/register';
  static const VERIFY_EMAIL = '/verify-email';
  static const FORGOT_PASSWORD = '/forgot-password';
  static const MAIN_SHELL = '/main-shell';
  static const LEGAL_WEBVIEW = '/legal-webview';
  static const PROFILE = '/profile';
  static const REPORT_ANSWER = '/report-answer';
  static const SAVED_ANSWERS = '/saved-answers';
  static const FEEDBACK_REPORTS = '/feedback-reports';
  static const VOICE_CHAT = '/voice-chat';
  static const VOICE_SETTINGS = '/voice-settings';
}
