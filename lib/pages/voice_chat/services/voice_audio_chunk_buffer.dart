import 'dart:collection';
import 'dart:typed_data';

/// One synthesized sentence of a reply: its audio and the words it speaks,
/// so the caption can show each sentence as it is heard.
typedef VoiceAudioChunk = ({Uint8List audio, String text});

/// Reply audio arrives out of order; this hands it back strictly in order.
class VoiceAudioChunkBuffer {
  final SplayTreeMap<int, VoiceAudioChunk> _chunks =
      SplayTreeMap<int, VoiceAudioChunk>();
  int _nextIndex = 0;

  bool get isEmpty => _chunks.isEmpty;

  void clear() {
    _chunks.clear();
    _nextIndex = 0;
  }

  void add(int index, VoiceAudioChunk chunk) {
    if (index < _nextIndex || _chunks.containsKey(index)) {
      return;
    }
    _chunks[index] = chunk;
  }

  VoiceAudioChunk? popNext() {
    final chunk = _chunks.remove(_nextIndex);
    if (chunk != null) {
      _nextIndex++;
    }
    return chunk;
  }
}
