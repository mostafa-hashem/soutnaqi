import 'dart:io';
import 'dart:typed_data';

import 'package:soutnaqi/core/errors/app_exception.dart';
import 'package:soutnaqi/features/separation/data/on_device/on_device_model_spec.dart';

/// Deinterleaved stereo float32 samples in [-1, 1].
class StereoSamples {
  const StereoSamples({required this.left, required this.right});

  final Float32List left;
  final Float32List right;

  int get length => left.length;
}

/// Reads/writes the fixed-format (44.1kHz, stereo, 16-bit PCM) WAV files the
/// on-device model expects, converting to/from float32 tensors.
class AudioTensorCodec {
  AudioTensorCodec._();

  /// Decodes a WAV file into deinterleaved per-channel float32 samples.
  ///
  /// Throws [AppException] if the file isn't exactly the format the model
  /// expects. `SeparationAudioIo.prepareWavInput` skips re-encoding when the
  /// input already has a `.wav` extension, so this check is the last line
  /// of defense against silently feeding the model mismatched audio.
  static Future<StereoSamples> decodeWav(String path) async {
    final bytes = await File(path).readAsBytes();
    if (bytes.length < 44 ||
        _tag(bytes, 0) != 'RIFF' ||
        _tag(bytes, 8) != 'WAVE') {
      throw const AppException(
        messageKey: 'separationFailed',
        cause: 'Not a valid WAV file',
      );
    }
    final data = ByteData.sublistView(bytes);

    int? channels;
    int? sampleRate;
    int? bitsPerSample;
    int? dataOffset;
    int? dataLength;

    var offset = 12;
    while (offset + 8 <= bytes.length) {
      final chunkId = _tag(bytes, offset);
      final chunkSize = data.getUint32(offset + 4, Endian.little);
      final bodyOffset = offset + 8;
      if (chunkId == 'fmt ') {
        channels = data.getUint16(bodyOffset + 2, Endian.little);
        sampleRate = data.getUint32(bodyOffset + 4, Endian.little);
        bitsPerSample = data.getUint16(bodyOffset + 14, Endian.little);
      } else if (chunkId == 'data') {
        dataOffset = bodyOffset;
        dataLength = chunkSize;
      }
      offset = bodyOffset + chunkSize + (chunkSize.isOdd ? 1 : 0);
    }

    if (channels == null ||
        sampleRate == null ||
        bitsPerSample == null ||
        dataOffset == null ||
        dataLength == null) {
      throw const AppException(
        messageKey: 'separationFailed',
        cause: 'WAV file is missing fmt/data chunks',
      );
    }
    if (sampleRate != OnDeviceModelSpec.sampleRate ||
        channels != OnDeviceModelSpec.channels ||
        bitsPerSample != 16) {
      throw AppException(
        messageKey: 'separationFailed',
        cause: 'Expected ${OnDeviceModelSpec.sampleRate}Hz/'
            '${OnDeviceModelSpec.channels}ch/16-bit WAV, got '
            '${sampleRate}Hz/${channels}ch/$bitsPerSample-bit',
      );
    }

    final frameCount = dataLength ~/ (channels * 2);
    final left = Float32List(frameCount);
    final right = Float32List(frameCount);
    var readOffset = dataOffset;
    for (var i = 0; i < frameCount; i++) {
      left[i] = data.getInt16(readOffset, Endian.little) / 32768.0;
      right[i] = data.getInt16(readOffset + 2, Endian.little) / 32768.0;
      readOffset += 4;
    }
    return StereoSamples(left: left, right: right);
  }

  /// Encodes deinterleaved float32 [-1, 1] samples back to a 16-bit PCM WAV.
  static Future<void> encodeWav({
    required String outputPath,
    required StereoSamples samples,
  }) async {
    final frameCount = samples.length;
    final dataLength = frameCount * 4;
    final buffer = ByteData(44 + dataLength);
    const bytesPerFrame = OnDeviceModelSpec.channels * 2;

    _writeTag(buffer, 0, 'RIFF');
    buffer.setUint32(4, 36 + dataLength, Endian.little);
    _writeTag(buffer, 8, 'WAVE');
    _writeTag(buffer, 12, 'fmt ');
    buffer.setUint32(16, 16, Endian.little);
    buffer.setUint16(20, 1, Endian.little); // PCM
    buffer.setUint16(22, OnDeviceModelSpec.channels, Endian.little);
    buffer.setUint32(24, OnDeviceModelSpec.sampleRate, Endian.little);
    buffer.setUint32(
      28,
      OnDeviceModelSpec.sampleRate * bytesPerFrame,
      Endian.little,
    );
    buffer.setUint16(32, bytesPerFrame, Endian.little);
    buffer.setUint16(34, 16, Endian.little);
    _writeTag(buffer, 36, 'data');
    buffer.setUint32(40, dataLength, Endian.little);

    var writeOffset = 44;
    for (var i = 0; i < frameCount; i++) {
      buffer.setInt16(
        writeOffset,
        _clampToInt16(samples.left[i]),
        Endian.little,
      );
      buffer.setInt16(
        writeOffset + 2,
        _clampToInt16(samples.right[i]),
        Endian.little,
      );
      writeOffset += 4;
    }

    await File(outputPath).writeAsBytes(buffer.buffer.asUint8List());
  }

  static int _clampToInt16(double sample) {
    final scaled = (sample * 32768.0).round();
    if (scaled > 32767) return 32767;
    if (scaled < -32768) return -32768;
    return scaled;
  }

  static String _tag(Uint8List bytes, int offset) {
    return String.fromCharCodes(bytes.sublist(offset, offset + 4));
  }

  static void _writeTag(ByteData data, int offset, String tag) {
    for (var i = 0; i < 4; i++) {
      data.setUint8(offset + i, tag.codeUnitAt(i));
    }
  }
}
