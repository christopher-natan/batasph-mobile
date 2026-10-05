import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:batasph_mobile/pages/voice_chat/services/spoken_clip_cache.dart';
import 'package:batasph_mobile/pages/voice_chat/services/tts_service.dart';
import 'package:batasph_mobile/pages/voice_chat/services/voice_greeting_service.dart';

void main() {
  late Directory cacheDirectory;
  late VoiceGreetingService service;
  late _FakeTtsService tts;

  setUp(() async {
    cacheDirectory = await Directory.systemTemp.createTemp('batasph-greeting-');
    service = VoiceGreetingService(
      cache: SpokenClipCache(cacheRoot: () async => cacheDirectory),
      random: Random(1),
    );
    tts = _FakeTtsService();
  });

  tearDown(() async {
    await cacheDirectory.delete(recursive: true);
  });

  test('uses the chosen voice name and varies consecutive greetings', () async {
    final first = await service.prepare(
      language: 'english',
      voice: 'luna',
      voiceName: 'Luna',
      tts: tts,
    );
    final second = await service.prepare(
      language: 'english',
      voice: 'luna',
      voiceName: 'Luna',
      tts: tts,
    );

    expect(first.text, contains('Luna'));
    expect(second.text, contains('Luna'));
    expect(first.text, isNot(second.text));
    expect(first.audio, isNotEmpty);
    expect(second.audio, isNotEmpty);
    expect(tts.synthesizedTexts, [first.text, second.text]);
  });

  test('uses Filipino greeting copy when Tagalog is selected', () async {
    final greeting = await service.prepare(
      language: 'tagalog',
      voice: 'aria',
      voiceName: 'Aria',
      tts: tts,
    );

    expect(greeting.text, contains('Aria'));
    expect(greeting.text, contains('BatasPH'));
    expect(greeting.voice, 'aria');
  });

  test(
    'reports a failed synthesis instead of returning a silent greeting',
    () async {
      tts.failSynthesis = true;

      expect(
        () => service.prepare(
          language: 'english',
          voice: 'luna',
          voiceName: 'Luna',
          tts: tts,
        ),
        throwsStateError,
      );
    },
  );
}

class _FakeTtsService implements TtsService {
  final synthesizedTexts = <String>[];
  bool failSynthesis = false;

  @override
  Future<Uint8List> synthesize(String text) async {
    synthesizedTexts.add(text);
    if (failSynthesis) throw StateError('TTS unavailable');
    return Uint8List.fromList([1, 2, 3]);
  }

  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> playAudio(Uint8List audioBytes) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}
