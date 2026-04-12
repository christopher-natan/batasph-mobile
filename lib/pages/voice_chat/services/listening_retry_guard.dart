enum ListeningEmptyResultAction { retry, idle }

class ListeningRetryGuard {
  ListeningRetryGuard({this.maxConsecutiveAutoRetries = 1});

  final int maxConsecutiveAutoRetries;
  int _consecutiveEmptyResults = 0;

  int get consecutiveEmptyResults => _consecutiveEmptyResults;

  void reset() {
    _consecutiveEmptyResults = 0;
  }

  void onSpeechCaptured(String transcript) {
    if (transcript.trim().isNotEmpty) {
      reset();
    }
  }

  ListeningEmptyResultAction onEmptyFinal({required bool autoContinue}) {
    if (!autoContinue) {
      reset();
      return ListeningEmptyResultAction.idle;
    }

    if (_consecutiveEmptyResults < maxConsecutiveAutoRetries) {
      _consecutiveEmptyResults++;
      return ListeningEmptyResultAction.retry;
    }

    return ListeningEmptyResultAction.idle;
  }
}
