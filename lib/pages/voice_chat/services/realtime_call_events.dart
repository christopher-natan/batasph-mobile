import 'dart:convert';

/// What the call controller needs from the OpenAI Realtime data channel
/// ("oai-events"). Every other server event is ignored.
sealed class RealtimeCallEvent {
  const RealtimeCallEvent();

  /// Parses one data-channel message; null for events the call ignores.
  static RealtimeCallEvent? parse(String message) {
    final Object? decoded;
    try {
      decoded = jsonDecode(message);
    } on FormatException {
      return null;
    }
    if (decoded is! Map<String, dynamic>) return null;
    return switch (decoded['type']) {
      'input_audio_buffer.speech_started' => const CallerSpeechStarted(),
      'input_audio_buffer.speech_stopped' => const CallerSpeechStopped(),
      'response.created' => const ResponseStarted(),
      'response.done' => ResponseFinished.fromJson(decoded),
      'output_audio_buffer.started' => const LunaAudioStarted(),
      // Cleared is Luna being interrupted: her audio stops early.
      'output_audio_buffer.stopped' ||
      'output_audio_buffer.cleared' => const LunaAudioStopped(),
      'conversation.item.input_audio_transcription.completed' =>
        CallerTranscript(decoded['transcript'] as String? ?? ''),
      'response.output_audio_transcript.done' => LunaTranscript(
        decoded['transcript'] as String? ?? '',
      ),
      'error' => RealtimeError.fromJson(decoded),
      _ => null,
    };
  }
}

/// The server VAD heard the caller start talking.
class CallerSpeechStarted extends RealtimeCallEvent {
  const CallerSpeechStarted();
}

/// The caller stopped talking; a reply follows.
class CallerSpeechStopped extends RealtimeCallEvent {
  const CallerSpeechStopped();
}

/// The model started a response (speech, tool calls, or both).
class ResponseStarted extends RealtimeCallEvent {
  const ResponseStarted();
}

/// The model finished a response. [functionCalls] are the tools it called,
/// in order; their outputs go back with `conversation.item.create`.
class ResponseFinished extends RealtimeCallEvent {
  const ResponseFinished({
    required this.status,
    required this.functionCalls,
    required this.spoke,
  });

  factory ResponseFinished.fromJson(Map<String, dynamic> json) {
    final response = json['response'] as Map<String, dynamic>? ?? const {};
    final output = response['output'] as List<dynamic>? ?? const [];
    final items = output.whereType<Map<String, dynamic>>();
    return ResponseFinished(
      status: response['status'] as String? ?? '',
      functionCalls: [
        for (final item in items)
          if (item['type'] == 'function_call') FunctionCall.fromJson(item),
      ],
      spoke: items.any((item) => item['type'] == 'message'),
    );
  }

  /// `completed`, `cancelled` (the caller interrupted), `failed`, ...
  final String status;
  final List<FunctionCall> functionCalls;

  /// Luna said something in this response (not only tool calls).
  final bool spoke;
}

class FunctionCall {
  const FunctionCall({
    required this.callId,
    required this.name,
    required this.arguments,
  });

  factory FunctionCall.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> arguments;
    try {
      arguments =
          jsonDecode(json['arguments'] as String? ?? '{}')
              as Map<String, dynamic>;
    } on Object {
      arguments = const {};
    }
    return FunctionCall(
      callId: json['call_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      arguments: arguments,
    );
  }

  final String callId;
  final String name;
  final Map<String, dynamic> arguments;
}

/// Luna's voice started playing on the phone.
class LunaAudioStarted extends RealtimeCallEvent {
  const LunaAudioStarted();
}

/// Luna's voice stopped playing: she finished, or was interrupted.
class LunaAudioStopped extends RealtimeCallEvent {
  const LunaAudioStopped();
}

/// What the caller said (for the logs only).
class CallerTranscript extends RealtimeCallEvent {
  const CallerTranscript(this.text);
  final String text;
}

/// What Luna said (for the logs only).
class LunaTranscript extends RealtimeCallEvent {
  const LunaTranscript(this.text);
  final String text;
}

class RealtimeError extends RealtimeCallEvent {
  const RealtimeError({required this.code, required this.message});

  factory RealtimeError.fromJson(Map<String, dynamic> json) {
    final error = json['error'] as Map<String, dynamic>? ?? const {};
    return RealtimeError(
      code: error['code'] as String? ?? '',
      message: error['message'] as String? ?? '',
    );
  }

  final String code;
  final String message;
}

/// The WebRTC connection itself failed or dropped.
class CallConnectionLost extends RealtimeCallEvent {
  const CallConnectionLost(this.reason);
  final String reason;
}
