import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInErrorUtil {
  const GoogleSignInErrorUtil._();

  static bool isCanceled(Object error) {
    return error is GoogleSignInException &&
        error.code == GoogleSignInExceptionCode.canceled;
  }

  static String diagnosticMessage(
    GoogleSignInException error, {
    required String packageName,
    required String serverClientId,
  }) {
    final buffer = StringBuffer()
      ..write('Google sign-in ${error.code.name}: ')
      ..write(error.description ?? 'No description provided.');

    if (_needsAndroidConfigHint(error)) {
      buffer
        ..write(
          ' If this happened after selecting an account, Android Credential'
          ' Manager may be masking a configuration problem.',
        )
        ..write(
          ' Check package name ($packageName), registered SHA-1/SHA-256, and'
          ' serverClientId ($serverClientId).',
        );
    }

    return buffer.toString();
  }

  static bool _needsAndroidConfigHint(GoogleSignInException error) {
    return error.code == GoogleSignInExceptionCode.canceled ||
        error.code == GoogleSignInExceptionCode.clientConfigurationError ||
        error.code == GoogleSignInExceptionCode.providerConfigurationError;
  }
}
