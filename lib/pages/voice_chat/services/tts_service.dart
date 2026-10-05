import 'dart:typed_data';

abstract class TtsService {
  Future<void> speak(String text);
  Future<Uint8List> synthesize(String text);
  Future<void> playAudio(Uint8List audioBytes);

  /// Drop to a low volume without stopping, and come back. Barge-in ducks
  /// the moment it hears speech and only stops once the speech is confirmed.
  Future<void> setDucked(bool ducked) async {}

  Future<void> stop();
  Future<void> dispose();
}
