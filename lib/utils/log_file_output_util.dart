import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Writes log lines to rotating files under [directory].
///
/// Design constraints, in priority order:
///
/// 1. **Never throw.** A logger that can crash the app is worse than no
///    logger. Every filesystem call is guarded; on the first failure file
///    output disables itself and says so once on the console.
/// 2. **Never block the UI.** [output] only appends to an in-memory buffer.
///    Actual writes happen on a short timer (or when the buffer gets large),
///    and at most one write is in flight at a time.
/// 3. **Bounded on disk.** One file per UTC day, rolled to `.1`, `.2`, ...
///    past [maxFileBytes]; files older than [retentionDays] are pruned at
///    startup.
///
/// Dates are UTC so lines line up with the backend, which logs and keys
/// everything in UTC.
class LogFileOutput extends LogOutput {
  LogFileOutput({
    required this.directory,
    required this.maxFileBytes,
    required this.retentionDays,
  });

  final Directory directory;
  final int maxFileBytes;
  final int retentionDays;

  static const _flushInterval = Duration(seconds: 1);
  static const _flushThresholdChars = 16 * 1024;
  static const _filePrefix = 'batasph-';
  static const _fileSuffix = '.log';

  final _buffer = StringBuffer();
  Timer? _flushTimer;
  bool _writing = false;
  bool _disabled = false;

  /// Creates the directory and prunes stale files. Safe to call when the
  /// filesystem is unavailable — file output just stays disabled.
  @override
  Future<void> init() async {
    try {
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      await _pruneOldFiles();
    } catch (e) {
      _disable('init failed: $e');
    }
  }

  @override
  void output(OutputEvent event) {
    if (_disabled) return;
    for (final line in event.lines) {
      _buffer.writeln(line);
    }
    if (_buffer.length >= _flushThresholdChars) {
      _scheduleFlush(immediate: true);
    } else {
      _scheduleFlush();
    }
  }

  /// Forces buffered lines to disk. Await this before the process exits or
  /// before handing the files to the user.
  Future<void> flush() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    await _write();
  }

  @override
  Future<void> destroy() => flush();

  /// All log files, newest first.
  Future<List<File>> files() async {
    try {
      if (!await directory.exists()) return const [];
      final files = await directory
          .list()
          .where((e) => e is File && _isLogFile(e.path))
          .cast<File>()
          .toList();
      files.sort((a, b) => b.path.compareTo(a.path));
      return files;
    } catch (_) {
      return const [];
    }
  }

  // ─── Internals ─────────────────────────────────────────────

  void _scheduleFlush({bool immediate = false}) {
    if (immediate) {
      _flushTimer?.cancel();
      _flushTimer = null;
      unawaited(_write());
      return;
    }
    _flushTimer ??= Timer(_flushInterval, () {
      _flushTimer = null;
      unawaited(_write());
    });
  }

  Future<void> _write() async {
    if (_disabled || _writing || _buffer.isEmpty) return;
    _writing = true;
    final chunk = _buffer.toString();
    _buffer.clear();
    try {
      final file = await _currentFile();
      await file.writeAsString(chunk, mode: FileMode.append, flush: true);
    } catch (e) {
      _disable('write failed: $e');
    } finally {
      _writing = false;
    }
    // Lines that arrived while we were writing.
    if (_buffer.isNotEmpty && !_disabled) _scheduleFlush();
  }

  /// Today's file, rolled to the next index if the current one is full.
  Future<File> _currentFile() async {
    final day = _utcDay(DateTime.now().toUtc());
    var index = 0;
    while (true) {
      final file = File(_pathFor(day, index));
      if (!await file.exists()) return file;
      if (await file.length() < maxFileBytes) return file;
      index++;
    }
  }

  Future<void> _pruneOldFiles() async {
    final cutoff = DateTime.now().toUtc().subtract(
      Duration(days: retentionDays),
    );
    await for (final entity in directory.list()) {
      if (entity is! File || !_isLogFile(entity.path)) continue;
      final day = _dayFromPath(entity.path);
      if (day != null && day.isBefore(cutoff)) {
        try {
          await entity.delete();
        } catch (_) {
          // A file we cannot delete is not worth failing startup over.
        }
      }
    }
  }

  void _disable(String reason) {
    if (_disabled) return;
    _disabled = true;
    _buffer.clear();
    // The one place this class talks to the console directly: the file sink
    // cannot report its own failure through the file sink.
    debugPrint('[BatasphLogger] file output disabled — $reason');
  }

  String _pathFor(String day, int index) {
    final suffix = index == 0 ? _fileSuffix : '.$index$_fileSuffix';
    return '${directory.path}${Platform.pathSeparator}$_filePrefix$day$suffix';
  }

  bool _isLogFile(String path) {
    final name = path.split(Platform.pathSeparator).last;
    return name.startsWith(_filePrefix) && name.endsWith(_fileSuffix);
  }

  /// Parses `batasph-2026-09-18.log` or `batasph-2026-09-18.3.log` back to a
  /// day.
  DateTime? _dayFromPath(String path) {
    final name = path.split(Platform.pathSeparator).last;
    final match = RegExp(r'^batasph-(\d{4}-\d{2}-\d{2})').firstMatch(name);
    if (match == null) return null;
    return DateTime.tryParse('${match.group(1)}T00:00:00Z');
  }

  static String _utcDay(DateTime utc) => utc.toIso8601String().substring(0, 10);
}
