import 'package:flutter_test/flutter_test.dart';
import 'package:batasph_mobile/pages/voice_chat/services/voice_farewell_service.dart';

void main() {
  test('recognizes short English, Tagalog and Taglish call endings', () {
    for (final phrase in [
      'Bye!',
      'That’s all for now, thank you.',
      'Thank u thats all for now',
      'Okay, goodbye',
      'Salamat po, yun lang muna.',
      'Sige, paalam!',
    ]) {
      expect(
        VoiceFarewellService.replyFor(phrase),
        VoiceFarewellService.farewellReply,
        reason: phrase,
      );
    }
  });

  test('speaks the fixed lines in Taglish', () {
    expect(VoiceFarewellService.farewellReply, contains('Ingat'));
    expect(VoiceFarewellService.silenceCheckIn, contains('nandiyan ka pa ba'));
    expect(
      VoiceFarewellService.silenceFarewell,
      allOf(contains('tumawag ulit'), contains('bye')),
    );
  });

  test('does not end a call for a legal question or casual thanks', () {
    for (final phrase in [
      'Can I say goodbye to my landlord?',
      'Thank you',
      'What does that mean for now?',
      'I said bye to my employer, can they fire me?',
    ]) {
      expect(VoiceFarewellService.replyFor(phrase), isNull, reason: phrase);
    }
  });
}
