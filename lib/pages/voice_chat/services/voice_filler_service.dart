import 'dart:math';

import 'package:flutter/services.dart';
import 'package:batasph_mobile/pages/voice_chat/services/voice_fillers.dart';
import 'package:batasph_mobile/utils/logger_util.dart';

/// A filler clip ready to play, with what it says.
typedef FillerClip = ({String text, Uint8List audio});

/// Holds the bundled filler clips in memory so [next] is instant.
class VoiceFillerService {
  VoiceFillerService({Random? random, AssetBundle? bundle})
    : _random = random ?? Random(),
      _bundle = bundle ?? rootBundle;

  final Random _random;
  final AssetBundle _bundle;
  final List<FillerClip> _clips = [];
  int? _lastIndex;

  int get readyCount => _clips.length;

  /// Loads every clip from the app bundle. A clip that fails to load is
  /// logged and left out of the rotation.
  Future<void> load() async {
    if (_clips.isNotEmpty) return;
    for (final entry in VoiceFillers.clips.entries) {
      try {
        final data = await _bundle.load(entry.key);
        _clips.add((text: entry.value, audio: data.buffer.asUint8List()));
      } catch (error, stackTrace) {
        BatasphLogger.error(
          '[Voice] Filler clip missing | ${entry.key}',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    BatasphLogger.log('[Voice] Fillers ready | clips=${_clips.length}');
  }

  /// A clip other than the previous one, or null before [load] finished.
  FillerClip? next() {
    if (_clips.isEmpty) return null;
    final last = _lastIndex;
    int index;
    if (last == null || _clips.length == 1) {
      index = _random.nextInt(_clips.length);
    } else {
      // Every index but the last one played.
      index = _random.nextInt(_clips.length - 1);
      if (index >= last) index++;
    }
    _lastIndex = index;
    return _clips[index];
  }
}
