import 'package:logger/logger.dart' show Level;

class AppConfig {
  static const appName = 'BatasPH';
  static const apiBaseUrl =
      'https://batasph-api-33656109674.asia-southeast1.run.app/api/v1';
  static const apiKey = '';
  static const chatMaxMessageLength = 500;

  /// Messages per page of `/chat/history`; older pages load on scroll-up.
  static const chatPageSize = 30;

  // Google Sign-In
  // Web/server OAuth client ID, passed to google_sign_in as `serverClientId`.
  // It is the audience Google stamps into the ID token, so it must match the
  // backend's GOOGLE_CLIENT_ID. This is NOT the per-app Android client ID.
  static const googleWebClientId =
      '33656109674-udj3u2i4eht0bbgguruc74sg4tekrpr6.apps.googleusercontent.com';

  // ─── Logging ──────────────────────────────────────────────
  /// Master switch. When false every BatasphLogger call returns immediately —
  /// no console output, no file output, no error hooks.
  static const loggingEnabled = true;

  /// Also write logs to files under `<app documents>/logs/`, one file per
  /// UTC day (`batasph-YYYY-MM-DD.log`). Console output is unaffected.
  static const fileLoggingEnabled = true;

  /// Minimum level that reaches the console and the file.
  static const logLevel = Level.debug;

  /// Log files older than this are deleted at startup.
  static const logRetentionDays = 7;

  /// A day's file rolls over to `batasph-YYYY-MM-DD.1.log`, `.2.log`, ... once
  /// it passes this size.
  static const logMaxFileBytes = 2 * 1024 * 1024; // 2 MB
}
