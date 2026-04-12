typedef SttResultCallback = void Function(String transcript, bool isFinal);
typedef SttErrorCallback = void Function(String error);
typedef SttTranscribingCallback = void Function();

abstract class SttService {
  SttResultCallback? onResult;
  SttErrorCallback? onError;
  SttTranscribingCallback? onTranscribing;

  bool get isActive;

  Future<void> warmUp();
  Future<void> startSession();
  Future<void> stopSession();
  Future<void> cancelSession();
  Future<void> dispose();
}
