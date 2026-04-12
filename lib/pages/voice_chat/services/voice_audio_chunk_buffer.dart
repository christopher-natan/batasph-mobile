import 'dart:collection';
import 'dart:typed_data';

class VoiceAudioChunkBuffer {
  final SplayTreeMap<int, Uint8List> _chunks = SplayTreeMap<int, Uint8List>();
  int _nextIndex = 0;

  bool get isEmpty => _chunks.isEmpty;

  void clear() {
    _chunks.clear();
    _nextIndex = 0;
  }

  void add(int index, Uint8List bytes) {
    if (index < _nextIndex || _chunks.containsKey(index)) {
      return;
    }
    _chunks[index] = bytes;
  }

  Uint8List? popNext() {
    final bytes = _chunks.remove(_nextIndex);
    if (bytes != null) {
      _nextIndex++;
    }
    return bytes;
  }
}
