import 'dart:math' as math;
import 'dart:typed_data';

import 'package:fftea/fftea.dart';
import 'package:soutnaqi/features/separation/data/on_device/on_device_model_spec.dart';

/// Torch-compatible MDX STFT and inverse with scratch space reused per job.
class MdxStft {
  static const _nFft = OnDeviceModelSpec.nFft;
  static const _hop = OnDeviceModelSpec.hopLength;
  static const _dimF = OnDeviceModelSpec.dimF;
  static const _dimT = OnDeviceModelSpec.dimT;
  static const _trim = OnDeviceModelSpec.trimSamples;
  static const _chunk = OnDeviceModelSpec.chunkSamples;
  static const _olaLength = _chunk + _nFft;

  static final _analysisWindow = Float64List.fromList(
    List.generate(_nFft, (i) => 0.5 - 0.5 * math.cos(2 * math.pi * i / _nFft)),
  );

  static final _inverseScale = _createInverseScale();

  final _fft = FFT(_nFft);
  final _freq = Float64x2List(_nFft);
  final _acc = Float64List(_olaLength);
  final _padded = Float64List(_olaLength);

  /// Packs [left real, left imag, right real, right imag, freq, time].
  void forward(Float32List left, Float32List right, Float32List spectrum) {
    _writeChannel(spectrum, 0, left);
    _writeChannel(spectrum, 2, right);
  }

  void inverse(Float32List spectrum, Float32List left, Float32List right) {
    _readChannel(spectrum, 0, left);
    _readChannel(spectrum, 2, right);
  }

  void _writeChannel(
    Float32List spectrum,
    int complexBase,
    Float32List samples,
  ) {
    // PyTorch center padding uses reflection at both ends.
    _padded.setRange(_trim, _trim + _chunk, samples);
    for (var i = 0; i < _trim; i++) {
      _padded[i] = samples[_trim - i];
      _padded[_trim + _chunk + i] = samples[_chunk - 2 - i];
    }

    final realBase = complexBase * _dimF * _dimT;
    final imagBase = realBase + _dimF * _dimT;
    for (var t = 0; t < _dimT; t++) {
      final start = t * _hop;
      for (var n = 0; n < _nFft; n++) {
        _freq[n] = Float64x2(_padded[start + n] * _analysisWindow[n], 0);
      }
      _fft.inPlaceFft(_freq);
      for (var f = 0; f < _dimF; f++) {
        final bin = _freq[f];
        final offset = f * _dimT + t;
        spectrum[realBase + offset] = bin.x;
        spectrum[imagBase + offset] = bin.y;
      }
    }
  }

  void _readChannel(Float32List spectrum, int complexBase, Float32List output) {
    _acc.fillRange(0, _olaLength, 0);
    final realBase = complexBase * _dimF * _dimT;
    final imagBase = realBase + _dimF * _dimT;
    final zero = Float64x2(0, 0);
    for (var t = 0; t < _dimT; t++) {
      // Bins outside the model's spectrum are zero, including Nyquist.
      _freq.fillRange(_dimF, _nFft - _dimF + 1, zero);
      for (var f = 0; f < _dimF; f++) {
        final offset = f * _dimT + t;
        final real = spectrum[realBase + offset];
        final imaginary = spectrum[imagBase + offset];
        _freq[f] = Float64x2(real, imaginary);
        if (f > 0) _freq[_nFft - f] = Float64x2(real, -imaginary);
      }

      // The real inverse equals the reversed real part of the forward FFT,
      // scaled by its length. Read directly into overlap-add scratch space.
      _fft.inPlaceFft(_freq);
      final start = t * _hop;
      _acc[start] += (_freq[0].x / _nFft) * _analysisWindow[0];
      for (var n = 1; n < _nFft; n++) {
        _acc[start + n] += (_freq[_nFft - n].x / _nFft) * _analysisWindow[n];
      }
    }
    for (var i = 0; i < _chunk; i++) {
      output[i] = _acc[_trim + i] * _inverseScale[i];
    }
  }

  static Float64List _createInverseScale() {
    final envelope = Float64List(_olaLength);
    for (var t = 0; t < _dimT; t++) {
      final start = t * _hop;
      for (var n = 0; n < _nFft; n++) {
        final weight = _analysisWindow[n];
        envelope[start + n] += weight * weight;
      }
    }
    final scale = Float64List(_chunk);
    for (var i = 0; i < _chunk; i++) {
      final weight = envelope[_trim + i];
      scale[i] = weight < 1e-8 ? 0 : 1 / weight;
    }
    return scale;
  }
}
