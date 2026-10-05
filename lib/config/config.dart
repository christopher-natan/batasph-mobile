import 'package:logger/logger.dart' show Level;

class AppConfig {
  static const appName = 'BatasPH';
  static const brandLogoAsset = 'assets/images/logo.png';

  /// The deployed API. A local run overrides it, e.g. with `adb reverse`:
  /// `--dart-define=API_BASE_URL=http://127.0.0.1:3000/api/v1`.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue:
        'https://batasph-api-33656109674.asia-southeast1.run.app/api/v1',
  );
  static const apiKey = '';
  // ─── Persona ──────────────────────────────────────────────
  /// The one face and voice of the app. The API's PERSONA constant must
  /// match the name, since answers introduce themselves with it.
  static const personaName = 'Atty. Luna';
  static const personaTagline = 'BatasPH AI Legal Guide';
  static const personaVoice = 'luna';
  static const personaAvatarAsset = 'assets/images/avatars/luna_face.jpg';

  // ─── Voice call tuning ────────────────────────────────────
  /// Silence that ends the caller's turn, in seconds. 2 is Memori's
  /// device-proven value (the STT services turn it into a 1.8s window);
  /// 1 cut callers off at every thinking pause.
  static const voiceSilenceSeconds = 2;

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
