import 'dart:math' as math;
import 'dart:typed_data';

import 'package:soutnaqi/features/separation/data/on_device/audio_tensor_codec.dart';
import 'package:soutnaqi/features/separation/data/on_device/mdx_stft.dart';
import 'package:soutnaqi/features/separation/data/on_device/on_device_model_spec.dart';
import 'package:soutnaqi/features/separation/data/separation_cancel_token.dart';

/// UVR MDX-Net overlap-add separation for [OnDeviceModelSpec].
///
/// Matches the non-denoise path in audio-separator's `MDXSeparator.demix` /
/// `run_model`: center pad, 25% Hann-blended chunks, STFT, zero the first
/// three bins, one ONNX pass, ISTFT. Vocals are the model output. Callers
/// apply [OnDeviceModelSpec.compensate] only when deriving the instrumental.
class MdxSeparator {
  MdxSeparator._();

  static Future<StereoSamples> separate({
    required StereoSamples mix,
    required Future<Float32List> Function(Float32List spectrum) runSpectrum,
    void Function(int chunkIndex, int totalChunks)? onProgress,
    SeparationCancelToken? cancelToken,
  }) async {
    const trim = OnDeviceModelSpec.trimSamples;
    const chunk = OnDeviceModelSpec.chunkSamples;
    const step = OnDeviceModelSpec.strideSamples;
    final length = mix.length;
    final remainder = length % OnDeviceModelSpec.genSize;
    final tail = OnDeviceModelSpec.genSize + trim - remainder;
    final mixtureLength = trim + length + tail;

    final starts = <int>[];
    for (var start = 0; start < mixtureLength; start += step) {
      starts.add(start);
    }

    final accLeft = Float64List(mixtureLength);
    final accRight = Float64List(mixtureLength);
    final divider = Float64List(mixtureLength);

    for (var index = 0; index < starts.length; index++) {
      cancelToken?.throwIfCancelled();
      final start = starts[index];
      final end = math.min(start + chunk, mixtureLength);
      final actual = end - start;

      final chunkLeft = Float32List(chunk);
      final chunkRight = Float32List(chunk);
      for (var i = 0; i < actual; i++) {
        final at = start + i;
        if (at < trim || at >= trim + length) continue;
        final sample = at - trim;
        chunkLeft[i] = mix.left[sample];
        chunkRight[i] = mix.right[sample];
      }

      final spectrum = await MdxStft.forward(left: chunkLeft, right: chunkRight);
      _zeroLowBins(spectrum);
      final predicted = await runSpectrum(spectrum);
      cancelToken?.throwIfCancelled();
      final wave = await MdxStft.inverse(predicted);
      final window = _numpyHanning(actual);

      for (var i = 0; i < actual; i++) {
        final weight = window[i];
        accLeft[start + i] += wave.left[i] * weight;
        accRight[start + i] += wave.right[i] * weight;
        divider[start + i] += weight;
      }

      onProgress?.call(index + 1, starts.length);
      await Future<void>.delayed(Duration.zero);
    }

    final left = Float32List(length);
    final right = Float32List(length);
    for (var i = 0; i < length; i++) {
      final weight = divider[trim + i];
      final scale = weight < 1e-8 ? 0.0 : 1.0 / weight;
      left[i] = accLeft[trim + i] * scale;
      right[i] = accRight[trim + i] * scale;
    }
    return StereoSamples(left: left, right: right);
  }

  /// UVR drops the first three frequency bins before inference.
  static void _zeroLowBins(Float32List spectrum) {
    const dimF = OnDeviceModelSpec.dimF;
    const dimT = OnDeviceModelSpec.dimT;
    for (var channel = 0; channel < 4; channel++) {
      for (var bin = 0; bin < 3; bin++) {
        final row = (channel * dimF + bin) * dimT;
        spectrum.fillRange(row, row + dimT, 0);
      }
    }
  }

  /// `numpy.hanning`, used by UVR to blend overlapping waveform chunks.
  static Float64List _numpyHanning(int length) {
    if (length <= 1) return Float64List(length)..fillRange(0, length, 1);
    final window = Float64List(length);
    for (var i = 0; i < length; i++) {
      window[i] = 0.5 - 0.5 * math.cos(2 * math.pi * i / (length - 1));
    }
    return window;
  }
}
