import 'dart:math';
import 'dart:typed_data';

import 'package:batasph_mobile/pages/voice_chat/services/spoken_clip_cache.dart';
import 'package:batasph_mobile/pages/voice_chat/services/tts_service.dart';
import 'package:batasph_mobile/pages/voice_chat/services/voice_fillers.dart';
import 'package:batasph_mobile/utils/logger_util.dart';

/// Which filler pool a turn draws from (see [VoiceFillers]).
enum FillerKind { checking, acknowledging }

/// Holds the filler clips for one voice in memory so [next] is instant.
///
/// A filler is only useful if it is ready at the moment the transcript is
/// final, so unlike the greeting the clips are warmed up ahead of time:
/// [warmUp] runs in the background when the call screen opens and fills any
/// missing clip through [SpokenClipCache] (disk first, one TTS call per
/// phrase per voice the first time ever). A phrase whose clip is not ready
/// is simply not offered.
class VoiceFillerService {
  VoiceFillerService({Random? random, SpokenClipCache? cache})
    : _random = random ?? Random(),
      _cache = cache ?? SpokenClipCache();

  static const String bucket = 'voice_fillers/v${VoiceFillers.version}';

  final Random _random;
  final SpokenClipCache _cache;
  final Map<FillerKind, Map<int, Uint8List>> _clips = {
    FillerKind.checking: {},
    FillerKind.acknowledging: {},
  };
  final Map<FillerKind, int?> _lastIndex = {};
  String? _voice;
  bool _warming = false;
  int _generation = 0;

  int get readyCount => _clips.values.fold(0, (sum, pool) => sum + pool.length);

  static List<String> phrasesOf(FillerKind kind) => switch (kind) {
    FillerKind.checking => VoiceFillers.checking,
    FillerKind.acknowledging => VoiceFillers.acknowledging,
  };

  static String _key(FillerKind kind, int index) => switch (kind) {
    FillerKind.checking => 'check$index',
    FillerKind.acknowledging => 'ack$index',
  };

  /// Loads every filler for [voice] into memory, synthesizing the ones the
  /// device has never heard in that voice. Sequential so a cold start does
  /// not fire a dozen TTS calls at once. Safe to call repeatedly: a call for
  /// the voice already warming is a no-op; a call for a different voice
  /// supersedes the in-flight one, which stops storing clips.
  Future<void> warmUp({required String voice, required TtsService tts}) async {
    if (_voice == voice && _warming) return;
    final generation = ++_generation;
    if (_voice != voice) {
      for (final pool in _clips.values) {
        pool.clear();
      }
      _lastIndex.clear();
      _voice = voice;
    }
    _warming = true;
    try {
      for (final kind in FillerKind.values) {
        final phrases = phrasesOf(kind);
        final pool = _clips[kind]!;
        for (var i = 0; i < phrases.length; i++) {
          if (generation != _generation) return; // superseded by another voice
          if (pool.containsKey(i)) continue;
          final audio = await _cache.getOrSynthesize(
            bucket: bucket,
            voice: voice,
            key: _key(kind, i),
            text: phrases[i],
            tts: tts,
          );
          if (generation != _generation) return;
          if (audio == null) {
            // Offline or throttled: stop here rather than hammer the backend.
            BatasphLogger.warning(
              '[Voice] Filler warm-up stopped at ${kind.name} $i/${phrases.length}',
            );
            return;
          }
          pool[i] = audio;
        }
      }
      BatasphLogger.log(
        '[Voice] Fillers ready | voice=$voice | clips=$readyCount',
      );
    } finally {
      if (generation == _generation) _warming = false;
    }
  }

  /// A ready clip from [kind]'s pool, never the same as that pool's
  /// previous pick, or null when none is ready yet (the caller skips it).
  Uint8List? next(FillerKind kind) {
    final pool = _clips[kind]!;
    if (pool.isEmpty) return null;
    final ready = pool.keys.toList()..sort();
    if (ready.length == 1) {
      _lastIndex[kind] = ready.single;
      return pool[ready.single];
    }
    final last = _lastIndex[kind];
    final candidates = ready.where((i) => i != last).toList();
    final index = candidates[_random.nextInt(candidates.length)];
    _lastIndex[kind] = index;
    return pool[index];
  }
}
