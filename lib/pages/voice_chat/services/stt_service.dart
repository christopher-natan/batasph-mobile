typedef SttResultCallback = void Function(String transcript, bool isFinal);
typedef SttErrorCallback = void Function(String error);
typedef SttTranscribingCallback = void Function();
typedef SttSpeechStartedCallback = void Function();
typedef SttIdleCallback = void Function();
typedef SttAudioLevelCallback = void Function(double dbfs);

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

  /// Fired for every captured frame with its RMS level in dBFS, whether or
  /// not the frame was sent. Muted frames count too — that is what makes the
  /// echo measurement free (see VoiceEchoProbe).
  SttAudioLevelCallback? onAudioLevel;

  bool get isActive;

  /// True when one session spans the whole call (listen → process → speak →
  /// listen) instead of one session per utterance. The controller then
  /// re-enters listening with [setMuted] rather than a new session.
  bool get supportsContinuousListening => false;

  /// Continuous services stop sending microphone audio while muted (the
  /// recorder keeps running so unmuting is instant). No-op elsewhere.
  ///
  /// Muting normally drops the audio the server still holds, so a
  /// half-sentence cut off by the mute is not glued onto the next turn. Pass
  /// [preserveBuffer] when that audio is wanted — during a barge-in the words
  /// spoken over the reply ARE the next turn.
  void setMuted(bool muted, {bool preserveBuffer = false}) {}

  /// While gated, captured audio is held back until someone actually speaks
  /// instead of being uplinked continuously. Used only for the assistant's
  /// own turn, where the mic stays open for barge-in; never gate the user's.
  void setUplinkGate(bool gated) {}

  /// Pre-warm expensive resources so startSession() is fast.
  Future<void> warmUp();
  Future<void> startSession();
  Future<void> stopSession();
  Future<void> cancelSession();
  Future<void> dispose();
}
