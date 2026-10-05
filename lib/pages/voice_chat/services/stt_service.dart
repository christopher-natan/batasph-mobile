typedef SttResultCallback = void Function(String transcript, bool isFinal);
typedef SttErrorCallback = void Function(String error);
typedef SttTranscribingCallback = void Function();
typedef SttSpeechStartedCallback = void Function();
typedef SttIdleCallback = void Function();

abstract class SttService {
  SttResultCallback? onResult;
  SttErrorCallback? onError;

  /// Fired when a speech turn ends and the service begins finalizing the
  /// transcript. The controller moves the UI from "listening" to
  /// "processing" on this, before the text arrives.
  SttTranscribingCallback? onTranscribing;

  /// Fired when the service detects speech beginning.
  SttSpeechStartedCallback? onSpeechStarted;

  /// Fired when a continuous session closed itself after a long silence.
  /// The service has already torn down; the controller only updates state.
  SttIdleCallback? onIdle;

  bool get isActive;

  /// True when one session spans the whole call (listen → process → speak →
  /// listen) instead of one session per utterance. The controller then
  /// re-enters listening with [setMuted] rather than a new session.
  bool get supportsContinuousListening => false;

  /// Continuous services stop sending microphone audio while muted (the
  /// recorder keeps running so unmuting is instant). No-op elsewhere.
  void setMuted(bool muted) {}

  /// Pre-warm expensive resources so startSession() is fast.
  Future<void> warmUp();
  Future<void> startSession();
  Future<void> stopSession();
  Future<void> cancelSession();
  Future<void> dispose();
}
