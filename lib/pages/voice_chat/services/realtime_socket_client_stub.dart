import 'package:batasph_mobile/pages/voice_chat/services/realtime_socket_client.dart';

class UnsupportedRealtimeSocketClient implements RealtimeSocketClient {
  @override
  Stream<Object?> get messages => const Stream.empty();

  @override
  Future<void> connect(String url, {Map<String, dynamic>? headers}) {
    throw UnsupportedError(
      'Realtime voice chat is not supported on this platform',
    );
  }

  @override
  void sendBytes(List<int> bytes) {}

  @override
  void sendText(String text) {}

  @override
  Future<void> close({int? code, String? reason}) async {}
}

RealtimeSocketClient createRealtimeSocketClientImpl() =>
    UnsupportedRealtimeSocketClient();
