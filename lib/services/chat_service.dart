import 'package:dio/dio.dart';
import 'package:batasph_mobile/data/models/chat_stream_event.dart';
import 'package:batasph_mobile/data/remote/chat_repository.dart';
import 'package:batasph_mobile/utils/logger_util.dart';

class ChatService {
  final _repository = ChatRepository();
  CancelToken? _cancelToken;

  Stream<ChatStreamEvent> streamMessage(
    String text, {
    String? mode,
    String? voice,
    List<String>? subjects,
  }) {
    _cancelToken = CancelToken();
    return _repository.streamMessage(
      text,
      cancelToken: _cancelToken,
      mode: mode,
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
}
