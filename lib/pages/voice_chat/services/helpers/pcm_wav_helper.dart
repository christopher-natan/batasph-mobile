import 'dart:typed_data';

/// Wraps 16-bit mono PCM in a WAV header so audioplayers can play it from
/// memory. Shared by every runtime-synthesized tone in the voice module.
Uint8List wrapPcmAsWav({required int sampleRate, required Uint8List pcmData}) {
  final byteRate = sampleRate * 2;
  final header = BytesBuilder();

  void addString(String value) {
    header.add(value.codeUnits);
  }

  void addUint32(int value) {
    header.add([
      value & 0xFF,
      (value >> 8) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 24) & 0xFF,
    ]);
  }

  void addUint16(int value) {
    header.add([value & 0xFF, (value >> 8) & 0xFF]);
  }

  addString('RIFF');
  addUint32(36 + pcmData.length);
  addString('WAVE');
  addString('fmt ');
  addUint32(16);
  addUint16(1);
  addUint16(1);
  addUint32(sampleRate);
  addUint32(byteRate);
  addUint16(2);
  addUint16(16);
  addString('data');
  addUint32(pcmData.length);
  header.add(pcmData);

  return header.takeBytes();
}

/// Encodes a stream of `[-1, 1]` samples as 16-bit little-endian PCM.
Uint8List encodePcm16(Iterable<double> samples) {
  final pcmBytes = BytesBuilder();
  for (final sample in samples) {
    final value = (sample * 32767).round().clamp(-32768, 32767);
    pcmBytes.addByte(value & 0xFF);
    pcmBytes.addByte((value >> 8) & 0xFF);
  }
  return pcmBytes.takeBytes();
}
