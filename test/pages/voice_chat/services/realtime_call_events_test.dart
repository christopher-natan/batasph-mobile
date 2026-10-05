import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:batasph_mobile/pages/voice_chat/services/realtime_call_events.dart';

void main() {
  RealtimeCallEvent? parse(Map<String, dynamic> json) =>
      RealtimeCallEvent.parse(jsonEncode(json));

  test('turn events', () {
    expect(
      parse({'type': 'input_audio_buffer.speech_started'}),
      isA<CallerSpeechStarted>(),
    );
    expect(
      parse({'type': 'input_audio_buffer.speech_stopped'}),
      isA<CallerSpeechStopped>(),
    );
    expect(parse({'type': 'response.created'}), isA<ResponseStarted>());
    expect(
      parse({'type': 'output_audio_buffer.started'}),
      isA<LunaAudioStarted>(),
    );
    expect(
      parse({'type': 'output_audio_buffer.stopped'}),
      isA<LunaAudioStopped>(),
    );
  });

  test('an interruption clears Luna\'s audio, which counts as stopped', () {
    expect(
      parse({'type': 'output_audio_buffer.cleared'}),
      isA<LunaAudioStopped>(),
    );
  });

  test('response.done carries the function calls in order', () {
    final event = parse({
      'type': 'response.done',
      'response': {
        'status': 'completed',
        'output': [
          {'type': 'message', 'role': 'assistant'},
          {
            'type': 'function_call',
            'call_id': 'call_1',
            'name': 'lookup_philippine_law',
            'arguments': '{"question":"Pwede ba akong paalisin?"}',
          },
          {
            'type': 'function_call',
            'call_id': 'call_2',
            'name': 'end_call',
            'arguments': '{}',
          },
        ],
      },
    });
    expect(event, isA<ResponseFinished>());
    final done = event! as ResponseFinished;
    expect(done.status, 'completed');
    expect(done.functionCalls.map((call) => call.name), [
      'lookup_philippine_law',
      'end_call',
    ]);
    expect(done.functionCalls.first.callId, 'call_1');
    expect(done.spoke, isTrue);
    expect(
      done.functionCalls.first.arguments['question'],
      'Pwede ba akong paalisin?',
    );
  });

  test('a response with only a tool call did not speak', () {
    final event = parse({
      'type': 'response.done',
      'response': {
        'status': 'completed',
        'output': [
          {
            'type': 'function_call',
            'call_id': 'call_9',
            'name': 'end_call',
            'arguments': '{}',
          },
        ],
      },
    });
    expect((event! as ResponseFinished).spoke, isFalse);
  });

  test('transcripts and errors', () {
    final caller = parse({
      'type': 'conversation.item.input_audio_transcription.completed',
      'transcript': 'Chris po',
    });
    expect((caller! as CallerTranscript).text, 'Chris po');
    final error = parse({
      'type': 'error',
      'error': {
        'code': 'conversation_already_has_active_response',
        'message': 'busy',
      },
    });
    expect(
      (error! as RealtimeError).code,
      'conversation_already_has_active_response',
    );
  });

  test('other events and garbage are ignored', () {
    expect(parse({'type': 'response.output_audio.delta'}), isNull);
    expect(RealtimeCallEvent.parse('not json'), isNull);
    expect(RealtimeCallEvent.parse('[1, 2]'), isNull);
  });
}
