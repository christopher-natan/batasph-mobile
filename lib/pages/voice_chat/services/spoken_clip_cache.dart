import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import 'package:batasph_mobile/pages/voice_chat/services/tts_service.dart';
import 'package:batasph_mobile/utils/logger_util.dart';

/// On-device cache of short synthesized clips (greetings, fillers) keyed by
/// bucket, voice and clip key:
///
///   `<app support dir>/<bucket>/<voice>/<key>.mp3`
///
/// Each clip is synthesized once per voice through the same TTS backend the
/// replies use, then read from disk forever after. The cache is a
/// convenience only — every read/write failure is logged and ignored, and a
/// failed synthesis returns null so callers skip the clip rather than block.
class SpokenClipCache {
  SpokenClipCache({Future<Directory> Function()? cacheRoot})
    : _cacheRoot = cacheRoot ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _cacheRoot;

  /// Cached bytes, or null when the clip has not been synthesized yet.
  Future<Uint8List?> read({
    required String bucket,
    required String voice,
    required String key,
  }) async {
    try {
      final file = await _file(bucket, voice, key);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      return bytes.isEmpty ? null : bytes;
    } catch (error) {
      BatasphLogger.debug(
        '[Voice] Clip cache read failed, treating as miss: $error',
      );
      return null;
    }
  }

  /// Cached bytes, else synthesize [text] and store it. Null when synthesis
  /// fails (offline, throttled) — never throws.
  Future<Uint8List?> getOrSynthesize({
    required String bucket,
    required String voice,
    required String key,
    required String text,
    required TtsService tts,
  }) async {
    final cached = await read(bucket: bucket, voice: voice, key: key);
    if (cached != null) {
      BatasphLogger.debug('[Voice] Clip cache hit | $bucket/$voice/$key');
      return cached;
    }

    final Uint8List audio;
    try {
      audio = await tts.synthesize(text);
    } catch (error, stackTrace) {
      BatasphLogger.error(
        '[Voice] Clip synthesis failed | $bucket/$voice/$key',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
    await _write(bucket, voice, key, audio);
    return audio;
  }

  Future<File> _file(String bucket, String voice, String key) async {
    final root = await _cacheRoot();
    final sep = Platform.pathSeparator;
    return File('${root.path}$sep$bucket$sep$voice$sep$key.mp3');
  }

  Future<void> _write(
    String bucket,
    String voice,
    String key,
    Uint8List audio,
  ) async {
    try {
      final file = await _file(bucket, voice, key);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(audio, flush: true);
      BatasphLogger.debug('[Voice] Clip cached | ${file.path}');
    } catch (error) {
      BatasphLogger.debug(
        '[Voice] Clip cache write failed, clip still usable this time: $error',
      );
    }
  }
}
