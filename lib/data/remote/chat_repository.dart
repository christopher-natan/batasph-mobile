import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:batasph_mobile/data/models/chat_source_model.dart';
import 'package:batasph_mobile/data/models/chat_stream_event.dart';
import 'package:batasph_mobile/data/remote/api_client.dart';

class ChatRepository {
  final _client = ApiClient().client;

  Stream<ChatStreamEvent> streamMessage(
    String text, {
    CancelToken? cancelToken,
    String? mode,
    String? voice,
    List<String>? subjects,
  }) async* {
    final payload = <String, dynamic>{'text': text, 'mode': mode ?? 'text'};
    if (voice != null && voice.isNotEmpty) {
      payload['voice'] = voice;
    }
    if (subjects != null && subjects.isNotEmpty) {
      payload['subjects'] = subjects;
    }

    final response = await _client.post(
      '/chat/stream',
      data: payload,
      cancelToken: cancelToken,
      options: Options(
        responseType: ResponseType.stream,
        headers: {'Accept': 'text/event-stream'},
        receiveTimeout: Duration.zero,
      ),
    );

    final stream = response.data.stream as Stream<List<int>>;
    var buffer = '';

    await for (final chunk in stream) {
      buffer += utf8.decode(chunk);

      while (buffer.contains('\n\n')) {
        final eventEnd = buffer.indexOf('\n\n');
        final rawEvent = buffer.substring(0, eventEnd);
        buffer = buffer.substring(eventEnd + 2);

        final event = _parseSseEvent(rawEvent);
        if (event != null) {
          yield event;
        }
      }
    }
  }

  ChatStreamEvent? _parseSseEvent(String rawEvent) {
    String? eventType;
    final dataLines = <String>[];

    for (final line in rawEvent.split('\n')) {
      if (line.startsWith('event: ')) {
        eventType = line.substring(7).trim();
      } else if (line.startsWith('data: ')) {
        dataLines.add(line.substring(6));
      }
    }

    if (eventType == null || dataLines.isEmpty) {
      return null;
    }

    try {
      final json = jsonDecode(dataLines.join('\n')) as Map<String, dynamic>;

      switch (eventType) {
        case 'token':
          return TokenEvent(json['text'] as String? ?? '');
        case 'audio':
          final audioBase64 =
              json['audioBase64'] as String? ?? json['audio'] as String? ?? '';
          return AudioEvent(
            audio: base64Decode(audioBase64),
            index: json['index'] as int? ?? 0,
            text: json['text'] as String? ?? '',
          );
        case 'done':
          final sourceList = json['sources'] as List? ?? const [];
          return DoneEvent(
            aiMessageId:
                json['aiResponseId'] as String? ??
                json['aiMessageId'] as String?,
            sources: sourceList
                .map(
                  (item) =>
                      ChatSourceModel.fromJson(item as Map<String, dynamic>),
                )
                .toList(),
            legalBasis: json['legalBasis'] != null
                ? List<String>.from(json['legalBasis'] as List)
                : const [],
            disclaimer: json['disclaimer'] as String? ?? '',
            responseLanguage: json['responseLanguage'] as String?,
            cached: json['cached'] as bool? ?? false,
            noResults: json['noResults'] as bool? ?? false,
            status: json['status'] as String?,
          );
        case 'error':
          return StreamErrorEvent(json['error'] as String? ?? 'Unknown error');
        case 'warning':
          return StreamWarningEvent(
            code: json['code'] as String? ?? '',
            message: json['message'] as String? ?? 'Warning',
          );
        default:
          return null;
      }
    } catch (_) {
      return null;
    }
  }
}
