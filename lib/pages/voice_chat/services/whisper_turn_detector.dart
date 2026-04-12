enum WhisperTurnAction { none, stopForEndOfSpeech }

class WhisperTurnDetector {
  WhisperTurnDetector({
    required this.speechThresholdDb,
    required this.silenceWindowSamples,
    this.speechStartWindowSamples = 2,
  });

  final double speechThresholdDb;
  final int silenceWindowSamples;
  final int speechStartWindowSamples;

  bool _hasDetectedSpeech = false;
  int _consecutiveSpeechSamples = 0;
  int _consecutiveSilentSamples = 0;

  bool get hasDetectedSpeech => _hasDetectedSpeech;

  WhisperTurnAction observe(double db) {
    final isSpeechSample = db > speechThresholdDb;

    if (isSpeechSample) {
      if (!_hasDetectedSpeech) {
        _consecutiveSpeechSamples++;
        if (_consecutiveSpeechSamples >= speechStartWindowSamples) {
          _hasDetectedSpeech = true;
        }
      }
      _consecutiveSilentSamples = 0;
      return WhisperTurnAction.none;
    }

    _consecutiveSpeechSamples = 0;
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
    _consecutiveSpeechSamples = 0;
    _consecutiveSilentSamples = 0;
  }
}
