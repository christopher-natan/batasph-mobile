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
  });

  final String text;
  final Uint8List audio;
  final String voice;
}

/// Picks a short introduction for each call and caches its synthesized audio.
/// The voice and language are part of the cache path, while the text hash
/// keeps variants separate. A failed synthesis is reported to the call flow
/// so the call does not silently begin without its greeting.
class VoiceGreetingService {
  VoiceGreetingService({SpokenClipCache? cache, Random? random})
    : _cache = cache ?? SpokenClipCache(),
      _random = random ?? Random();

  static const String bucket = 'voice_greetings/v2';
  static final Map<String, int> _lastVariantByLanguage = {};

  final SpokenClipCache _cache;
  final Random _random;

  Future<PreparedGreeting> prepare({
    required String language,
    required String voice,
    required String voiceName,
    required TtsService tts,
  }) async {
    final isTagalog = language == 'tagalog';
    final greetingLanguage = isTagalog ? 'tagalog' : 'english';
    final variants = isTagalog
        ? <String>[
            'Kumusta! Ako si $voiceName, ang BatasPH AI legal assistant mo. Ano ang maitutulong ko?',
            'Hello! Si $voiceName ito mula sa BatasPH. Ano ang tanong mo tungkol sa batas?',
            'Maligayang pagdating sa BatasPH. Ako si $voiceName, ang AI legal assistant mo. Ano ang gusto mong malaman?',
          ]
        : <String>[
            'Hello, this is $voiceName, your BatasPH AI legal assistant. How can I help?',
            'Hi, I am $voiceName from BatasPH. What legal question can I help you with?',
            'Welcome to BatasPH. I am $voiceName, your AI legal assistant. What would you like to ask?',
          ];

    final lastVariant = _lastVariantByLanguage[greetingLanguage];
    var variant = _random.nextInt(variants.length);
    if (variant == lastVariant) {
      variant = (variant + 1) % variants.length;
    }
    _lastVariantByLanguage[greetingLanguage] = variant;

    final text = variants[variant];
    final audio = await _cache.getOrSynthesize(
      bucket: bucket,
      voice: voice,
      key: '${greetingLanguage}_${_stableHash(text)}',
      text: text,
      tts: tts,
    );
    if (audio == null) {
      throw StateError('Unable to prepare voice greeting');
    }

    BatasphLogger.log(
      '[Voice] Greeting ready | language=$greetingLanguage | voice=$voice'
      ' | variant=$variant | bytes=${audio.length} | "$text"',
    );
    return PreparedGreeting(text: text, audio: audio, voice: voice);
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
