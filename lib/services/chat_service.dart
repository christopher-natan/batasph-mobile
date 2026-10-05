import 'package:dio/dio.dart';
import 'package:batasph_mobile/data/models/chat_greeting_model.dart';
import 'package:batasph_mobile/data/models/chat_message_model.dart';
import 'package:batasph_mobile/data/models/chat_stream_event.dart';
import 'package:batasph_mobile/data/remote/chat_repository.dart';
import 'package:batasph_mobile/utils/logger_util.dart';

class ChatService {
  final _repository = ChatRepository();
  CancelToken? _cancelToken;

  Stream<ChatStreamEvent> streamMessage(
    String text, {
    String? mode,
    String? language,
    String? voice,
    List<String>? subjects,
  }) {
    _cancelToken = CancelToken();
    return _repository.streamMessage(
      text,
      cancelToken: _cancelToken,
      mode: mode,
      language: language,
      voice: voice,
      subjects: subjects,
    );
  }

  void cancelStream() {
    if (_cancelToken != null && !_cancelToken!.isCancelled) {
      BatasphLogger.log('[Chat] Cancelling in-flight stream');
    }
    _cancelToken?.cancel('User cancelled');
    _cancelToken = null;
  }

  Future<ChatGreetingModel> getGreeting({String? language}) {
    return _repository.getGreeting(language: language);
  }

  Future<List<ChatMessageModel>> getHistory({int? limit, DateTime? before}) {
    return _repository.getHistory(limit: limit, before: before);
  }

  Future<void> clearHistory() async {
    try {
      await _repository.clearHistory();
    } catch (error, stackTrace) {
      BatasphLogger.error(
        '[Chat] Clear history request failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> deleteMessages(List<String> messageIds) async {
    try {
      await _repository.deleteMessages(messageIds);
    } catch (error, stackTrace) {
      BatasphLogger.error(
        '[Chat] Delete messages request failed | ids=$messageIds',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
