import 'package:dio/dio.dart';

/// Reads the user-facing message out of a failed BatasPH API call.
class ApiErrorUtil {
  const ApiErrorUtil._();

  /// The API's own message when it sent one, otherwise [fallback].
  static String message(DioException error, {required String fallback}) {
    final status = error.response?.statusCode;
    if (status == 429) {
      return 'Too many attempts. Please wait a minute and try again.';
    }
    if (status == 404) {
      return 'BatasPH API auth endpoints are not available yet.';
    }

    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String) {
        return message;
      }
      // class-validator failures arrive as a list, one entry per rule.
      if (message is List && message.isNotEmpty) {
        return message.first.toString();
      }
    }
    return fallback;
  }

  /// Login refused because the account's email has not been verified yet.
  static bool isEmailNotVerified(DioException error) {
    final data = error.response?.data;
    return error.response?.statusCode == 403 &&
        data is Map<String, dynamic> &&
        data['error'] == 'EMAIL_NOT_VERIFIED';
  }
}
