import 'dart:io';
import 'dart:typed_data';

import 'package:soutnaqi/features/separation/data/on_device/on_device_model_spec.dart';

/// Reads and writes raw, interleaved stereo float32 LE without whole-file loads.
class MdxPcmReader {
  MdxPcmReader(this._file);

  static const bytesPerFrame = 8;
  final RandomAccessFile _file;
  final _bytes = Uint8List(OnDeviceModelSpec.chunkSamples * bytesPerFrame);

  Future<int> frameCount() async {
    final length = await _file.length();
    if (length == 0 || length % bytesPerFrame != 0) {
      throw const FormatException('Invalid stereo float PCM length');
    }
    return length ~/ bytesPerFrame;
  }

  Future<void> read(
    Float32List left,
    Float32List right,
    int offset,
    int count,
  ) async {
    final end = count * bytesPerFrame;
    var position = 0;
    while (position < end) {
      final read = await _file.readInto(_bytes, position, end);
      if (read == 0) throw const FormatException('Truncated stereo float PCM');
      position += read;
    }
    final data = ByteData.sublistView(_bytes);
    for (var i = 0; i < count; i++) {
      final base = i * bytesPerFrame;
      left[offset + i] = data.getFloat32(base, Endian.little);
      right[offset + i] = data.getFloat32(base + 4, Endian.little);
    }
  }
}

class MdxPcmWriter {
  MdxPcmWriter(this._file);

  final RandomAccessFile _file;
  final _bytes = Uint8List(
    OnDeviceModelSpec.strideSamples * MdxPcmReader.bytesPerFrame,
  );

  Future<void> write(Float32List left, Float32List right, int count) async {
    final data = ByteData.sublistView(_bytes);
    for (var i = 0; i < count; i++) {
      final base = i * MdxPcmReader.bytesPerFrame;
      data.setFloat32(base, left[i], Endian.little);
      data.setFloat32(base + 4, right[i], Endian.little);
    }
    await _file.writeFrom(_bytes, 0, count * MdxPcmReader.bytesPerFrame);
  }
}
