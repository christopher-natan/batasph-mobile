import 'dart:convert';

import 'package:logger/logger.dart';

class BatasphLogger {
  BatasphLogger._();

  static final _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      noBoxingByDefault: false,
    ),
  );

  static void log(String message) {
    _logger.i(message);
  }

  static void error(String message) {
    _logger.e(message);
  }

  static void warning(String message) {
    _logger.w(message);
  }

  static void apiRequest(
    String method,
    String url, {
    dynamic body,
  }) {
    final buffer = StringBuffer()..writeln('$method $url');
    if (body != null) {
      buffer.writeln('Body: ${_prettyJson(body)}');
    }
    _logger.d(buffer.toString().trimRight());
  }

  static void apiResponse(
    String method,
    String url, {
    required int statusCode,
    dynamic body,
  }) {
    final buffer = StringBuffer()..writeln('$statusCode $method $url');
    if (body != null) {
      buffer.writeln('Body: ${_prettyJson(body)}');
    }
    if (statusCode >= 400) {
      _logger.e(buffer.toString().trimRight());
    } else {
      _logger.d(buffer.toString().trimRight());
    }
  }

  static void apiError(
    String method,
    String url, {
    required Object error,
  }) {
    _logger.e('$method $url\n$error');
  }

  static String _prettyJson(dynamic data) {
    try {
      if (data is String) {
        data = jsonDecode(data);
      }
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (_) {
      return data.toString();
    }
  }
}
