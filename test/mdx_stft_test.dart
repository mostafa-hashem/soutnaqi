import 'dart:math' as math;
import 'dart:typed_data';

import 'package:fftea/fftea.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soutnaqi/features/separation/data/on_device/mdx_stft.dart';
import 'package:soutnaqi/features/separation/data/on_device/on_device_model_spec.dart';

void main() {
  test('fftea real FFT round-trips a short buffer', () {
    final fft = FFT(8);
    final input = Float64List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
    final back = fft.realInverseFft(fft.realFft(input));
    for (var i = 0; i < input.length; i++) {
      expect(back[i], closeTo(input[i], 1e-9));
    }
  });

  test('MDX STFT round-trips one model window', () async {
    const length = OnDeviceModelSpec.chunkSamples;
    final left = Float32List(length);
    final right = Float32List(length);
    for (var i = 0; i < length; i++) {
      left[i] = 0.2 * math.sin(i * 0.07) + 0.05 * math.sin(i * 0.013);
      right[i] = 0.15 * math.sin(i * 0.05);
    }

    final wave = await MdxStft.inverse(
      await MdxStft.forward(left: left, right: right),
    );

    const margin = OnDeviceModelSpec.trimSamples;
    for (var i = margin; i < length - margin; i += 64) {
      expect(wave.left[i], closeTo(left[i], 1e-3));
      expect(wave.right[i], closeTo(right[i], 1e-3));
    }
  });
}
