import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

import 'package:batasph_mobile/config/config.dart';
import 'package:batasph_mobile/utils/log_file_output_util.dart';

/// The app's single logging facade.
///
/// Every call is a no-op when [AppConfig.loggingEnabled] is false, so leaving
/// calls in hot paths costs one boolean check. Output goes to the console
/// (boxed, coloured) and, when [AppConfig.fileLoggingEnabled] is set, to
/// plain-text files under `<app documents>/logs/` via [LogFileOutput].
///
/// Call [init] once from `main()` before `runApp`. Until then, calls still
/// reach the console so early boot problems are not lost; only the file sink
/// and the global error hooks wait for [init].
///
/// Message convention: prefix a tag in brackets so a file is greppable by
/// subsystem, e.g. `'[Chat] Stream done | tokens=412'`. Tags in use:
/// `[Session]`, `[Lifecycle]`, `[Nav]`, `[Auth]`, `[Chat]`, `[Voice]`,
/// `[STT]`, `[TTS]`, `[Logs]`, `[Uncaught]`.
class BatasphLogger {
  BatasphLogger._();

  static bool get _enabled => AppConfig.loggingEnabled;

  // Two loggers, one per destination, because a Logger has exactly one
  // printer and the two destinations want different formats: boxes and ANSI
  // colour on the console, greppable single lines in the file.
  static final Logger _console = _buildConsoleLogger();
  static Logger? _file;
  static LogFileOutput? _fileOutput;
  static bool _initialised = false;

  // ─── Setup ─────────────────────────────────────────────────

  /// Wires the file sink and the global error hooks. Idempotent.
  static Future<void> init() async {
    if (!_enabled || _initialised) return;
    _initialised = true;

    _installErrorHooks();

    if (!AppConfig.fileLoggingEnabled) return;
    try {
      final docs = await getApplicationDocumentsDirectory();
      final output = LogFileOutput(
        directory: Directory('${docs.path}${Platform.pathSeparator}logs'),
        maxFileBytes: AppConfig.logMaxFileBytes,
        retentionDays: AppConfig.logRetentionDays,
      );
      await output.init();
      _fileOutput = output;
      _file = Logger(
        level: AppConfig.logLevel,
        filter: ProductionFilter(),
        printer: _FileLinePrinter(),
        output: output,
      );
      log('[Logs] File logging -> ${output.directory.path}');
    } catch (e) {
      // Console logging still works; say so once and carry on.
      _console.e('[Logs] File logging unavailable: $e');
    }

    _logSessionHeader();
  }

  /// One block at the top of every session so a shared file is
  /// self-describing: what device, what build mode, what config. Read this
  /// first when a user sends a log.
  static void _logSessionHeader() {
    final mode = kReleaseMode
        ? 'release'
        : (kProfileMode ? 'profile' : 'debug');
    log(
      '[Session] ──────────────────────────────────────\n'
      'app:      ${AppConfig.appName}\n'
      'os:       ${Platform.operatingSystem} ${Platform.operatingSystemVersion}\n'
      'locale:   ${Platform.localeName}\n'
      'mode:     $mode\n'
      'api:      ${AppConfig.apiBaseUrl}\n'
      'logLevel: ${AppConfig.logLevel.name}\n'
      'utc:      ${DateTime.now().toUtc().toIso8601String()}\n'
      'local:    ${DateTime.now().toIso8601String()} (${DateTime.now().timeZoneName})',
    );
  }

  /// Routes uncaught framework and platform errors through the logger so they
  /// land in the file, not just the debug console.
  static void _installErrorHooks() {
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      error(
        '[Uncaught] Flutter framework error',
        error: details.exception,
        stackTrace: details.stack,
      );
      // Keep the default behaviour (red screen in debug, etc.).
      if (previous != null) {
        previous(details);
      } else {
        FlutterError.presentError(details);
      }
    };

    PlatformDispatcher.instance.onError = (err, stack) {
      error('[Uncaught] Platform/async error', error: err, stackTrace: stack);
      // Returning true marks it handled, which stops a release build from
      // dying on an error we have already recorded.
      return true;
    };
  }

  /// Flushes buffered file output. Await before exit or before reading files.
  static Future<void> flush() async => _fileOutput?.flush();

  /// The on-device log files, newest first. Empty when file logging is off.
  static Future<List<File>> logFiles() async =>
      _fileOutput?.files() ?? const [];

  // ─── Levels ────────────────────────────────────────────────

  static void trace(String message) {
    if (!_enabled) return;
    _console.t(message);
    _file?.t(message);
  }

  static void debug(String message) {
    if (!_enabled) return;
    _console.d(message);
    _file?.d(message);
  }

  static void log(String message) {
    if (!_enabled) return;
    _console.i(message);
    _file?.i(message);
  }

  static void warning(String message, {Object? error, StackTrace? stackTrace}) {
    if (!_enabled) return;
    _console.w(message, error: error, stackTrace: stackTrace);
    _file?.w(message, error: error, stackTrace: stackTrace);
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    if (!_enabled) return;
    _console.e(message, error: error, stackTrace: stackTrace);
    _file?.e(message, error: error, stackTrace: stackTrace);
  }

  // ─── Tagged helpers ────────────────────────────────────────

  /// Route changes. Wired to GetMaterialApp.routingCallback in main.dart, so
  /// every screen is covered without touching any page.
  static void nav(String message) => log('[Nav] $message');

  /// App foreground/background transitions.
  static void lifecycle(String message) => log('[Lifecycle] $message');

  // ─── API (called from the Dio interceptor) ─────────────────

  static void apiRequest(String method, String url, {dynamic body}) {
    if (!_enabled) return;
    final buffer = StringBuffer()..writeln('$method $url');
    if (body != null) {
      buffer.writeln('Body: ${_prettyJson(body)}');
    }
    debug(buffer.toString().trimRight());
  }

  static void apiResponse(
    String method,
    String url, {
    required int statusCode,
    dynamic body,
    Duration? elapsed,
  }) {
    if (!_enabled) return;
    final buffer = StringBuffer()
      ..writeln('$statusCode $method $url${_ms(elapsed)}');
    if (body != null) {
      buffer.writeln('Body: ${_prettyJson(body)}');
    }
    final text = buffer.toString().trimRight();
    if (statusCode >= 400) {
      error(text);
    } else {
      debug(text);
    }
  }

  static void apiError(
    String method,
    String url, {
    required Object error,
    Duration? elapsed,
  }) {
    if (!_enabled) return;
    BatasphLogger.error('$method $url${_ms(elapsed)}\n$error');
  }

  static String _ms(Duration? d) => d == null ? '' : ' | ${d.inMilliseconds}ms';

  // ─── Internals ─────────────────────────────────────────────

  static Logger _buildConsoleLogger() {
    return Logger(
      level: AppConfig.logLevel,
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 5,
        lineLength: 80,
        noBoxingByDefault: false,
      ),
    );
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

/// One greppable line per log call, UTC timestamp first:
///
/// ```
/// 2026-09-18T05:45:12.345Z I [Chat] Stream done | tokens=412
/// 2026-09-18T05:45:13.001Z E [Uncaught] Platform/async error
///     error: SocketException: ...
///     #0  ...
/// ```
///
/// Continuation lines are indented so a multi-line message or stack trace
/// stays visually attached to its header line.
class _FileLinePrinter extends LogPrinter {
  static const _levelTag = {
    Level.trace: 'T',
    Level.debug: 'D',
    Level.info: 'I',
    Level.warning: 'W',
    Level.error: 'E',
    Level.fatal: 'F',
  };

  @override
  List<String> log(LogEvent event) {
    final stamp = event.time.toUtc().toIso8601String();
    final tag = _levelTag[event.level] ?? '?';
    final messageLines = event.message.toString().split('\n');

    final lines = <String>['$stamp $tag ${messageLines.first}'];
    for (final line in messageLines.skip(1)) {
      lines.add('    $line');
    }
    if (event.error != null) {
      lines.add('    error: ${event.error}');
    }
    final stack = event.stackTrace;
    if (stack != null) {
      for (final line in stack.toString().trimRight().split('\n')) {
        lines.add('    $line');
      }
    }
    return lines;
  }
}
