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
  static const HOME = _Paths.HOME;
  static const SETTINGS = _Paths.SETTINGS;
  static const PROFILE = _Paths.PROFILE;
  static const VOICE_CHAT = _Paths.VOICE_CHAT;
}

abstract class _Paths {
  _Paths._();
  static const SPLASH = '/splash';
  static const ONBOARDING = '/onboarding';
  static const LOGIN = '/login';
  static const REGISTER = '/register';
  static const VERIFY_EMAIL = '/verify-email';
  static const FORGOT_PASSWORD = '/forgot-password';
  static const HOME = '/home';
  static const SETTINGS = '/settings';
  static const PROFILE = '/profile';
  static const VOICE_CHAT = '/voice-chat';
}
