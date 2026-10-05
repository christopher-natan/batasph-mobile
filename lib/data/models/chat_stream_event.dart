import 'dart:typed_data';

import 'package:batasph_mobile/data/models/chat_source_model.dart';

sealed class ChatStreamEvent {}

class TokenEvent extends ChatStreamEvent {
  final String text;

  TokenEvent(this.text);
}

class AudioEvent extends ChatStreamEvent {
  final Uint8List audio;
  final int index;

  /// The sentence this chunk speaks, so captions can follow the voice.
  final String text;

  AudioEvent({required this.audio, required this.index, required this.text});
}

class DoneEvent extends ChatStreamEvent {
  final String? aiMessageId;
  final List<ChatSourceModel> sources;
  final List<String> legalBasis;
  final String disclaimer;
  final String? responseLanguage;
  final bool cached;
  final bool noResults;
  final String? status;

  DoneEvent({
    this.aiMessageId,
    required this.sources,
    required this.legalBasis,
    required this.disclaimer,
    required this.responseLanguage,
    required this.cached,
    required this.noResults,
    this.status,
  });
}

class StreamErrorEvent extends ChatStreamEvent {
  final String message;

  StreamErrorEvent(this.message);
}

class StreamWarningEvent extends ChatStreamEvent {
  final String code;
  final String message;

  StreamWarningEvent({required this.code, required this.message});
}
