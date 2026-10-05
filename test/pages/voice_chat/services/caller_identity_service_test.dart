import 'package:flutter_test/flutter_test.dart';
import 'package:batasph_mobile/pages/voice_chat/services/caller_identity_service.dart';

void main() {
  group('readName', () {
    void expectName(String transcript, String name) {
      final reply = CallerIdentityService.readName(transcript);
      expect(reply.kind, CallerReplyKind.name, reason: transcript);
      expect(reply.name, name, reason: transcript);
    }

    test('reads a name however it is introduced', () {
      expectName('Chris.', 'Chris');
      expectName('My name is Chris.', 'Chris');
      expectName("Hi, I'm Chris po.", 'Chris');
      expectName('This is Maria.', 'Maria');
      expectName('Ako si Juan.', 'Juan');
      expectName('Ako po si Ana.', 'Ana');
      expectName('Ang pangalan ko ay Rico.', 'Rico');
      expectName('Juan dela Cruz', 'Juan');
      expectName('You can call me Jojo.', 'Jojo');
      expectName('My name is Chris and I have a question.', 'Chris');
    });

    test('a caller who goes straight to a question is not named', () {
      expect(
        CallerIdentityService.readName(
          "I'm asking about my land title, pwede ba?",
        ).kind,
        CallerReplyKind.question,
      );
      expect(
        CallerIdentityService.readName(
          'Ano ang karapatan ko as a tenant?',
        ).kind,
        CallerReplyKind.question,
      );
    });

    test('noise and non-names are unclear', () {
      for (final transcript in ['', 'Um.', 'Hello?', 'Yes.', 'Ano po?']) {
        expect(
          CallerIdentityService.readName(transcript).kind,
          CallerReplyKind.unclear,
          reason: transcript,
        );
      }
    });
  });

  group('readConfirmation', () {
    CallerReply confirm(String transcript) =>
        CallerIdentityService.readConfirmation(transcript, 'Chris');

    test('yes, in English or Tagalog, confirms', () {
      for (final transcript in [
        'Yes.',
        "Yes, it's me.",
        'Oo.',
        'Opo.',
        'Ako nga.',
        'Yes, this is Chris.',
        'Chris po.',
        'Yeah, I have a question about my lease.',
      ]) {
        expect(
          confirm(transcript).kind,
          CallerReplyKind.confirmed,
          reason: transcript,
        );
      }
    });

    test('a different name replaces the saved one', () {
      for (final (transcript, name) in [
        ('No, this is Maria.', 'Maria'),
        ('Hindi, si Ana ito.', 'Ana'),
        ('No, Maria.', 'Maria'),
        ("I'm Rico.", 'Rico'),
        ('Maria po.', 'Maria'),
      ]) {
        final reply = confirm(transcript);
        expect(reply.kind, CallerReplyKind.name, reason: transcript);
        expect(reply.name, name, reason: transcript);
      }
    });

    test('no without a name asks for it', () {
      for (final transcript in ['No.', 'Hindi po.', 'Nope.']) {
        expect(
          confirm(transcript).kind,
          CallerReplyKind.denied,
          reason: transcript,
        );
      }
    });

    test('a straight question is answered without changing the name', () {
      expect(
        confirm('Pwede ba akong ma-evict kahit nagbabayad ako?').kind,
        CallerReplyKind.question,
      );
    });
  });

  group('API reply', () {
    test('reads a name with the question said alongside it', () {
      final reply = CallerReply.fromJson({
        'kind': 'name',
        'name': 'Chris',
        'question': 'may tanong ako about sa lupa namin',
      });
      expect(reply.kind, CallerReplyKind.name);
      expect(reply.name, 'Chris');
      expect(reply.question, 'may tanong ako about sa lupa namin');
    });

    test('rejects a name reply without a name', () {
      expect(
        () => CallerReply.fromJson({'kind': 'name', 'name': null}),
        throwsFormatException,
      );
    });

    test('the on-phone question reading keeps the whole reply', () {
      final reply = CallerIdentityService.readName(
        'Ano ang karapatan ko as a tenant?',
      );
      expect(reply.question, 'Ano ang karapatan ko as a tenant?');
    });
  });

  test('every reply line uses the name it is given', () {
    final identity = CallerIdentityService();
    for (var i = 0; i < 10; i++) {
      expect(identity.welcomeNew('Chris'), contains('Chris'));
      expect(identity.welcomeBack('Chris'), contains('Chris'));
      expect(identity.nameUpdated('Chris'), contains('Chris'));
    }
  });
}
