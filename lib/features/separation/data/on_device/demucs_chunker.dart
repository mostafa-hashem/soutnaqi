import 'dart:typed_data';

import 'package:soutnaqi/features/separation/data/on_device/audio_tensor_codec.dart';
import 'package:soutnaqi/features/separation/data/on_device/on_device_model_spec.dart';

/// Splits a full-length stereo mix into fixed-length, overlapping chunks
/// sized to the model's segment length, runs each chunk through inference,
/// and reassembles the per-chunk stem outputs into continuous signals via
/// linear-fade overlap-add.
///
/// Mirrors the reference Python implementation's `separate()` function
/// (https://huggingface.co/StemSplitio/htdemucs-ft-vocals-onnx, `infer.py`)
/// exactly — same segment/overlap/stride math and the same linear
/// transition window — so behavior matches the model author's own
/// reference inference.
class DemucsChunker {
  DemucsChunker._();

  static final Float32List _window = _buildTransitionWindow();

  static Float32List _buildTransitionWindow() {
    const segment = OnDeviceModelSpec.chunkSamples;
    const transition = OnDeviceModelSpec.overlapSamples;
    final window = Float32List(segment)..fillRange(0, segment, 1.0);
    for (var i = 0; i < transition; i++) {
      final fade = i / (transition - 1);
      window[i] = fade;
      window[segment - 1 - i] = fade;
    }
    return window;
  }

  /// Runs [runChunk] once per model-sized chunk of [mix] and overlap-adds
  /// the results. [runChunk] receives one stereo chunk, zero-padded to
  /// exactly [OnDeviceModelSpec.chunkSamples], and must return the model's
  /// full stem output for that chunk, shaped `[source][channel][sample]`.
  ///
  /// Returns one [StereoSamples] per entry in [OnDeviceModelSpec.sources],
  /// each the length of the original [mix].
  static Future<List<StereoSamples>> process({
    required StereoSamples mix,
    required Future<List<List<Float32List>>> Function(StereoSamples chunk)
        runChunk,
    void Function(int chunkIndex, int totalChunks)? onProgress,
  }) async {
    final totalLength = mix.length;
    const segment = OnDeviceModelSpec.chunkSamples;
    const stride = OnDeviceModelSpec.strideSamples;

    var chunkCount = (totalLength + stride - 1) ~/ stride;
    if (chunkCount < 1) chunkCount = 1;

    final sourceCount = OnDeviceModelSpec.sources.length;
    final outLeft = List.generate(
      sourceCount,
      (_) => Float32List(totalLength),
    );
    final outRight = List.generate(
      sourceCount,
      (_) => Float32List(totalLength),
    );
    final weight = Float32List(totalLength);

    for (var i = 0; i < chunkCount; i++) {
      final start = i * stride;
      final end = (start + segment > totalLength)
          ? totalLength
          : start + segment;
      final chunkLength = end - start;

      final chunkLeft = Float32List(segment);
      final chunkRight = Float32List(segment);
      chunkLeft.setRange(0, chunkLength, mix.left, start);
      chunkRight.setRange(0, chunkLength, mix.right, start);

      final stems = await runChunk(
        StereoSamples(left: chunkLeft, right: chunkRight),
      );

      for (var s = 0; s < sourceCount; s++) {
        final stemLeft = stems[s][0];
        final stemRight = stems[s][1];
        for (var j = 0; j < chunkLength; j++) {
          final w = _window[j];
          outLeft[s][start + j] += stemLeft[j] * w;
          outRight[s][start + j] += stemRight[j] * w;
        }
      }
      for (var j = 0; j < chunkLength; j++) {
        weight[start + j] += _window[j];
      }

      onProgress?.call(i + 1, chunkCount);
      await Future<void>.delayed(Duration.zero);
    }

    return List.generate(sourceCount, (s) {
      final left = Float32List(totalLength);
      final right = Float32List(totalLength);
      for (var j = 0; j < totalLength; j++) {
        final w = weight[j] < 1e-8 ? 1e-8 : weight[j];
        left[j] = outLeft[s][j] / w;
        right[j] = outRight[s][j] / w;
      }
      return StereoSamples(left: left, right: right);
    });
  }
}
