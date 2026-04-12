enum WhisperTurnAction { none, stopForEndOfSpeech }

class WhisperTurnDetector {
  WhisperTurnDetector({
    required this.speechThresholdDb,
    required this.silenceWindowSamples,
  });

  final double speechThresholdDb;
  final int silenceWindowSamples;

  bool _hasDetectedSpeech = false;
  int _consecutiveSilentSamples = 0;

  bool get hasDetectedSpeech => _hasDetectedSpeech;

  WhisperTurnAction observe(double db) {
    final isSpeechSample = db > speechThresholdDb;

    if (isSpeechSample) {
      _hasDetectedSpeech = true;
      _consecutiveSilentSamples = 0;
      return WhisperTurnAction.none;
    }

    if (!_hasDetectedSpeech) {
      return WhisperTurnAction.none;
    }

    _consecutiveSilentSamples++;
    if (_consecutiveSilentSamples >= silenceWindowSamples) {
      _consecutiveSilentSamples = 0;
      return WhisperTurnAction.stopForEndOfSpeech;
    }

    return WhisperTurnAction.none;
  }

  void reset() {
    _hasDetectedSpeech = false;
    _consecutiveSilentSamples = 0;
  }
}
