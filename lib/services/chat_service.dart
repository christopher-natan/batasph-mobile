import 'package:dio/dio.dart';
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
    _cancelToken?.cancel('User cancelled');
    _cancelToken = null;
  }

  Future<List<ChatMessageModel>> getHistory({int? limit, DateTime? before}) {
    return _repository.getHistory(limit: limit, before: before);
  }

  Future<void> clearHistory() async {
    try {
      await _repository.clearHistory();
    } catch (error) {
      BatasphLogger.error('Failed to clear chat history: $error');
      rethrow;
    }
  }

  Future<void> deleteMessages(List<String> messageIds) async {
    try {
      await _repository.deleteMessages(messageIds);
    } catch (error) {
      BatasphLogger.error('Failed to delete chat messages: $error');
      rethrow;
    }
  }
}
