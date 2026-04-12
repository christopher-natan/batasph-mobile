import 'dart:typed_data';

abstract class TtsService {
  Future<void> speak(String text);
  Future<Uint8List> synthesize(String text);
  Future<void> playAudio(Uint8List audioBytes);
  Future<void> stop();
  Future<void> dispose();
}
