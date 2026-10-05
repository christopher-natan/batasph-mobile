import 'package:flutter_test/flutter_test.dart';
import 'package:batasph_mobile/pages/voice_chat/services/voice_farewell_service.dart';

void main() {
  test('recognizes short English and Filipino call endings', () {
    for (final phrase in [
      'Bye!',
      'That’s all for now, thank you.',
      'Thank u thats all for now',
      'Okay, goodbye',
      'Salamat po, yun lang muna.',
      'Sige, paalam!',
    ]) {
      expect(
        VoiceFarewellService.replyFor(phrase, language: 'english'),
        contains('goodbye'),
        reason: phrase,
      );
    }
  });

  test('uses Filipino farewell when answer language is Tagalog', () {
    expect(
      VoiceFarewellService.replyFor('Paalam', language: 'tagalog'),
      contains('Ingat'),
    );
  });

  test('provides natural silence check-in and farewell prompts', () {
    expect(
      VoiceFarewellService.silenceCheckIn(language: 'english'),
      contains('still there'),
    );
    expect(
      VoiceFarewellService.silenceFarewell(language: 'english'),
      allOf(contains('call again anytime'), contains('goodbye')),
    );
    expect(
      VoiceFarewellService.silenceCheckIn(language: 'tagalog'),
      contains('nandiyan ka pa ba'),
    );
    expect(
      VoiceFarewellService.silenceFarewell(language: 'tagalog'),
      contains('anumang oras'),
    );
  });

  test('does not end a call for a legal question or casual thanks', () {
    for (final phrase in [
      'Can I say goodbye to my landlord?',
      'Thank you',
      'What does that mean for now?',
      'I said bye to my employer, can they fire me?',
    ]) {
      expect(
        VoiceFarewellService.replyFor(phrase, language: 'english'),
        isNull,
        reason: phrase,
      );
    }
  });
}
