import 'dart:io';

import 'package:batasph_mobile/pages/voice_chat/services/realtime_socket_client.dart';

class IoRealtimeSocketClient implements RealtimeSocketClient {
  WebSocket? _socket;

  @override
  Stream<Object?> get messages => _socket!.cast<Object?>();

  @override
  Future<void> connect(String url, {Map<String, dynamic>? headers}) async {
    _socket = await WebSocket.connect(
      url,
      headers: headers?.map((key, value) => MapEntry(key, '$value')),
    );
  }

  @override
  void sendText(String text) {
    _socket?.add(text);
  }

  @override
  void sendBytes(List<int> bytes) {
    _socket?.add(bytes);
  }

  @override
  Future<void> close({int? code, String? reason}) async {
    await _socket?.close(code, reason);
    _socket = null;
  }
}

RealtimeSocketClient createRealtimeSocketClientImpl() =>
    IoRealtimeSocketClient();
