import 'dart:math' as math;
import 'dart:typed_data';

import 'package:fftea/fftea.dart';
import 'package:soutnaqi/features/separation/data/on_device/audio_tensor_codec.dart';
import 'package:soutnaqi/features/separation/data/on_device/on_device_model_spec.dart';

/// Torch-compatible STFT used by UVR's MDX separator.
///
/// Forward: reflect-pad by `n_fft/2`, periodic Hann window, real FFT, pack
/// stereo as `[left real, left imag, right real, right imag, freq, time]`
/// and keep the first [OnDeviceModelSpec.dimF] bins.
/// Inverse undoes that packing and the center pad.
class MdxStft {
  MdxStft._();

  static final FFT _fft = FFT(OnDeviceModelSpec.nFft);
  static final Float64List _analysisWindow = _periodicHann(OnDeviceModelSpec.nFft);

  /// Spectrum shaped `[4, dimF, dimT]`, row-major with time as the last axis.
  ///
  /// Yields every few frames so a chunk of 512 FFTs does not freeze the UI.
  static Future<Float32List> forward({
    required Float32List left,
    required Float32List right,
  }) async {
    final spec = Float32List(OnDeviceModelSpec.spectrumElementCount);
    await _writeChannel(spec, 0, left);
    await _writeChannel(spec, 2, right);
    return spec;
  }

  static Future<StereoSamples> inverse(Float32List spectrum) async {
    const chunk = OnDeviceModelSpec.chunkSamples;
    const trim = OnDeviceModelSpec.trimSamples;
    const olaLength = chunk + OnDeviceModelSpec.nFft;
    final accLeft = Float64List(olaLength);
    final accRight = Float64List(olaLength);
    final envelope = Float64List(olaLength);
    await _accumulate(spectrum, 0, accLeft, envelope, writeEnvelope: true);
    await _accumulate(spectrum, 2, accRight, envelope, writeEnvelope: false);

    final left = Float32List(chunk);
    final right = Float32List(chunk);
    for (var i = 0; i < chunk; i++) {
      final weight = envelope[trim + i];
      final scale = weight < 1e-8 ? 0.0 : 1.0 / weight;
      left[i] = accLeft[trim + i] * scale;
      right[i] = accRight[trim + i] * scale;
    }
    return StereoSamples(left: left, right: right);
  }

  static Future<void> _writeChannel(
    Float32List spec,
    int complexBase,
    Float32List samples,
  ) async {
    const nFft = OnDeviceModelSpec.nFft;
    const hop = OnDeviceModelSpec.hopLength;
    const dimF = OnDeviceModelSpec.dimF;
    const dimT = OnDeviceModelSpec.dimT;
    final padded = _reflectPad(samples);
    final frame = Float64List(nFft);

    for (var t = 0; t < dimT; t++) {
      final start = t * hop;
      for (var n = 0; n < nFft; n++) {
        frame[n] = padded[start + n] * _analysisWindow[n];
      }
      final freq = _fft.realFft(frame);
      for (var f = 0; f < dimF; f++) {
        final bin = freq[f];
        spec[(complexBase * dimF + f) * dimT + t] = bin.x;
        spec[((complexBase + 1) * dimF + f) * dimT + t] = bin.y;
      }
      if (t % 4 == 3) await Future<void>.delayed(Duration.zero);
    }
  }

  static Future<void> _accumulate(
    Float32List spectrum,
    int complexBase,
    Float64List acc,
    Float64List envelope, {
    required bool writeEnvelope,
  }) async {
    const nFft = OnDeviceModelSpec.nFft;
    const hop = OnDeviceModelSpec.hopLength;
    const dimF = OnDeviceModelSpec.dimF;
    const dimT = OnDeviceModelSpec.dimT;
    const nBins = OnDeviceModelSpec.frequencyBins;

    for (var t = 0; t < dimT; t++) {
      final freq = Float64x2List(nFft);
      for (var f = 0; f < dimF; f++) {
        freq[f] = Float64x2(
          spectrum[(complexBase * dimF + f) * dimT + t],
          spectrum[((complexBase + 1) * dimF + f) * dimT + t],
        );
      }
      for (var f = 1; f < nBins - 1; f++) {
        final bin = freq[f];
        freq[nFft - f] = Float64x2(bin.x, -bin.y);
      }
      final time = _fft.realInverseFft(freq);
      final start = t * hop;
      for (var n = 0; n < nFft; n++) {
        final window = _analysisWindow[n];
        acc[start + n] += time[n] * window;
        if (writeEnvelope) envelope[start + n] += window * window;
      }
      if (t % 4 == 3) await Future<void>.delayed(Duration.zero);
    }
  }

  /// PyTorch `reflect` pad of `n_fft/2` on both sides.
  static Float64List _reflectPad(Float32List samples) {
    const trim = OnDeviceModelSpec.trimSamples;
    final padded = Float64List(samples.length + OnDeviceModelSpec.nFft);
    for (var i = 0; i < trim; i++) {
      padded[i] = samples[trim - i];
    }
    for (var i = 0; i < samples.length; i++) {
      padded[trim + i] = samples[i];
    }
    final n = samples.length;
    for (var i = 0; i < trim; i++) {
      padded[trim + n + i] = samples[n - 2 - i];
    }
    return padded;
  }

  /// `torch.hann_window(..., periodic=True)`.
  static Float64List _periodicHann(int length) {
    final window = Float64List(length);
    for (var n = 0; n < length; n++) {
      window[n] = 0.5 - 0.5 * math.cos(2 * math.pi * n / length);
    }
    return window;
  }
}
