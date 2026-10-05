import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:batasph_mobile/pages/voice_chat/services/barge_in_detector.dart';
import 'package:batasph_mobile/pages/voice_chat/services/echo_text_guard.dart';

void main() {
  late List<String> events;
  late BargeInDetector detector;

  setUp(() {
    events = [];
    detector = BargeInDetector(
      onDuck: () => events.add('duck'),
      onConfirm: (text) => events.add('confirm:$text'),
      onRelease: () => events.add('release'),
    );
  });

  test('ducks on speech and stops only once real words confirm it', () {
    detector.onSpeechStarted();
    detector.onTranscript('teka', isEcho: false);
    detector.onTranscript('teka lang po', isEcho: false);

    expect(events, ['duck', 'confirm:teka lang po']);
  });

  test('Tagalog and English backchannels never interrupt', () {
    detector.onSpeechStarted();
    detector.onTranscript('oo opo sige', isEcho: false);
    detector.onTranscript('mm hmm okay yeah', isEcho: false);

    expect(events, ['duck']);
  });

  test('echo of our own reply never confirms', () {
    detector.onSpeechStarted();
    detector.onTranscript('you can file a complaint with DOLE', isEcho: true);

    expect(events, ['duck']);
  });

  test('a duck with no words is released as a false alarm', () {
    fakeAsync((async) {
      detector.onSpeechStarted();
      async.elapse(const Duration(milliseconds: 1300));
      expect(events, ['duck', 'release']);
    });
  });

  test('reset releases an outstanding duck so the next reply is not quiet', () {
    detector.onSpeechStarted();
    detector.reset();
    expect(events, ['duck', 'release']);
  });

  group('EchoTextGuard', () {
    test('recognises a run of our own words', () {
      final guard = EchoTextGuard()
        ..remember(
          'Kung tinanggal ka sa trabaho nang walang abiso, magreklamo ka sa DOLE.',
        );
      expect(
        guard.looksLikeEcho('tinanggal ka sa trabaho nang walang'),
        isTrue,
      );
    });

    test('accepts a user turn that only reuses a few words', () {
      final guard = EchoTextGuard()
        ..remember('You can file a complaint with DOLE within the year.');
      expect(guard.looksLikeEcho('how do I complain to DOLE online'), isFalse);
    });
  });
}
