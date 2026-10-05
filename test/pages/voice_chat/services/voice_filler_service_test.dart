import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:batasph_mobile/pages/voice_chat/services/voice_filler_service.dart';
import 'package:batasph_mobile/pages/voice_chat/services/voice_fillers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads every chosen take from the app bundle', () async {
    final service = VoiceFillerService();
    await service.load();
    expect(service.readyCount, VoiceFillers.clips.length);
    expect(service.readyCount, 24);
  });

  test('never plays the same filler twice in a row', () async {
    final service = VoiceFillerService(random: Random(7));
    await service.load();
    var previous = service.next()!;
    final heard = <String>{previous.text};
    for (var i = 0; i < 300; i++) {
      final clip = service.next()!;
      expect(clip.text, isNot(previous.text));
      expect(clip.audio, isNotEmpty);
      heard.add(clip.text);
      previous = clip;
    }
    expect(heard.length, VoiceFillers.clips.length);
  });

  test('offers nothing before the clips are loaded', () {
    expect(VoiceFillerService().next(), isNull);
  });
}
