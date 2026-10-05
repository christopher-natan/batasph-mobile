abstract class RealtimeSocketClient {
  Stream<Object?> get messages;

  Future<void> connect(String url, {Map<String, dynamic>? headers});

  void sendText(String text);

  void sendBytes(List<int> bytes);

  Future<void> close({int? code, String? reason});
}
