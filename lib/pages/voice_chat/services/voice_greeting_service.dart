import 'dart:math';
import 'dart:typed_data';

import 'package:batasph_mobile/pages/voice_chat/services/spoken_clip_cache.dart';
import 'package:batasph_mobile/pages/voice_chat/services/tts_service.dart';
import 'package:batasph_mobile/utils/logger_util.dart';

class PreparedGreeting {
  const PreparedGreeting({
    required this.text,
    required this.audio,
    required this.voice,
    required this.callerName,
  });

  final String text;
  final Uint8List audio;
  final String voice;

  /// The saved name the greeting asks to confirm; null when it asks for the
  /// caller's name instead.
  final String? callerName;
}

/// Picks a short introduction for each call and caches its synthesized audio.
/// A first-time caller is asked their name; a returning one is asked to
/// confirm the saved name. The voice is part of the cache path, while the
/// text hash keeps variants (and names) separate. A failed synthesis is reported to the call flow
/// so the call does not silently begin without its greeting.
class VoiceGreetingService {
  VoiceGreetingService({SpokenClipCache? cache, Random? random})
    : _cache = cache ?? SpokenClipCache(),
      _random = random ?? Random();

  /// Bump when the wording or the voice settings change, so cached audio is
  /// not replayed.
  static const String bucket = 'voice_greetings/v4';
  static int? _lastVariant;

  /// Taglish, like every answer. [voiceName] is the spoken name; with a
  /// [callerName] the greeting asks whether it is them again.
  static List<String> variantsFor(String voiceName, {String? callerName}) =>
      callerName == null
      ? [
          'Hi, this is $voiceName. May I ask your name?',
          'Hello! Si $voiceName ito ng BatasPH. Ano ang pangalan mo?',
          'Hi there, $voiceName here! Before we start, may I ask your name?',
        ]
      : [
          'Hi, this is $voiceName. Am I speaking with $callerName again?',
          'Hello! Si $voiceName ito. Si $callerName ba ulit ito?',
          'Hi, $voiceName here! Is this $callerName again?',
        ];

  final SpokenClipCache _cache;
  final Random _random;

  Future<PreparedGreeting> prepare({
    required String voice,
    required String voiceName,
    required TtsService tts,
    String? callerName,
  }) async {
    final variants = variantsFor(voiceName, callerName: callerName);
    var variant = _random.nextInt(variants.length);
    if (variant == _lastVariant) {
      variant = (variant + 1) % variants.length;
    }
    _lastVariant = variant;

    final text = variants[variant];
    final audio = await _cache.getOrSynthesize(
      bucket: bucket,
      voice: voice,
      key: 'taglish_${_stableHash(text)}',
      text: text,
      tts: tts,
    );
    if (audio == null) {
      throw StateError('Unable to prepare voice greeting');
    }

    BatasphLogger.log(
      '[Voice] Greeting ready | voice=$voice'
      ' | variant=$variant | bytes=${audio.length} | "$text"',
    );
    return PreparedGreeting(
      text: text,
      audio: audio,
      voice: voice,
      callerName: callerName,
    );
  }

  static String _stableHash(String value) {
    var hash = 0x811C9DC5;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
