import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:soutnaqi/features/separation/data/on_device/mdx_separator.dart';
import 'package:soutnaqi/features/separation/data/on_device/mdx_stft.dart';
import 'package:soutnaqi/features/separation/data/on_device/on_device_model_spec.dart';
import 'package:soutnaqi/features/separation/data/separation_cancel_token.dart';
import 'package:soutnaqi/features/separation/data/separation_target.dart';

const _chunk = OnDeviceModelSpec.chunkSamples;
const _step = OnDeviceModelSpec.strideSamples;
const _trim = OnDeviceModelSpec.trimSamples;
const _gen = OnDeviceModelSpec.genSize;

void main() {
  test(
    'short input runs only the window that contributes to the result',
    () async {
      final mix = Float32List(44100)..[123] = 0.4;
      final separated = await _stream(mix, SeparationTarget.vocals);
      expect(separated.calls, 1);
      expect(separated.samples.length, mix.length);
      expect(separated.samples[123].abs(), greaterThan(0.01));
    },
  );

  test(
    'streaming matches whole-file overlap-add across irregular tail windows',
    () async {
      // This length produces two contributing windows shorter than the model input.
      final mix = Float32List(975361);
      for (var i = 0; i < mix.length; i++) {
        mix[i] = (math.sin(i * 0.035) + math.cos(i * 0.29)) * 0.2;
      }
      final expected = _wholeFileReference(mix);
      final vocals = await _stream(mix, SeparationTarget.vocals);
      final music = await _stream(mix, SeparationTarget.instrumental);
      var vocalError = 0.0;
      var musicError = 0.0;
      for (var i = 0; i < mix.length; i++) {
        vocalError = math.max(
          vocalError,
          (expected[i] - vocals.samples[i]).abs(),
        );
        final instrumental =
            mix[i] - expected[i] * OnDeviceModelSpec.compensate;
        musicError = math.max(
          musicError,
          (instrumental - music.samples[i]).abs(),
        );
      }
      expect(vocalError, lessThan(1e-6));
      expect(musicError, lessThan(1e-6));
      expect(vocals.calls, 6);
    },
  );

  test('cancel stops the pipeline before starting the next window', () async {
    final token = SeparationCancelToken();
    var passes = 0;
    var writes = 0;
    final spectrum = Float32List(OnDeviceModelSpec.spectrumElementCount);
    await expectLater(
      MdxSeparator.separate(
        frameCount: _step * 2,
        readFrames: (_, _, _, _) async {},
        writeFrames: (_, _, _) async => writes++,
        spectrum: spectrum,
        runSpectrum: () {
          passes++;
          return spectrum;
        },
        target: SeparationTarget.vocals,
        cancelToken: token,
        onProgress: (completed, _) {
          if (completed == 1) token.cancel();
        },
      ),
      throwsA(
        predicate(
          (Object error) => error.toString().contains('separationCancelled'),
        ),
      ),
    );
    expect(passes, 1);
    expect(writes, 1);
  });
}

Future<({Float32List samples, int calls})> _stream(
  Float32List mix,
  SeparationTarget target,
) async {
  final result = Float32List(mix.length);
  final spectrum = Float32List(OnDeviceModelSpec.spectrumElementCount);
  var read = 0;
  var written = 0;
  var calls = 0;
  final progress = <int>[];
  await MdxSeparator.separate(
    frameCount: mix.length,
    readFrames: (left, right, offset, count) async {
      left.setRange(offset, offset + count, mix, read);
      for (var i = 0; i < count; i++) {
        right[offset + i] = -mix[read + i];
      }
      read += count;
    },
    writeFrames: (left, right, count) async {
      expect(count, inInclusiveRange(1, _step));
      result.setRange(written, written + count, left);
      expect(right[count - 1], closeTo(-left[count - 1], 1e-6));
      written += count;
    },
    spectrum: spectrum,
    runSpectrum: () {
      calls++;
      _scaleTestSpectrum(spectrum, calls);
      return spectrum;
    },
    target: target,
    onProgress: (completed, total) {
      progress.add(completed);
      expect(completed, lessThanOrEqualTo(total));
    },
  );
  expect(read, mix.length);
  expect(written, mix.length);
  expect(progress, List.generate(calls + 1, (index) => index));
  return (samples: result, calls: calls);
}

void _scaleTestSpectrum(Float32List spectrum, int step) {
  // Make overlapping predictions differ so normalization mistakes are visible.
  for (var i = 0; i < spectrum.length; i++) {
    spectrum[i] *= step.isOdd ? 0.7 : 0.2;
  }
}

Float32List _wholeFileReference(Float32List mix) {
  final paddedLength = _trim + mix.length + _gen + _trim - mix.length % _gen;
  final acc = Float32List(paddedLength);
  final divider = Float32List(paddedLength);
  final chunk = Float32List(_chunk);
  final wave = Float32List(_chunk);
  final right = Float32List(_chunk);
  final spectrum = Float32List(OnDeviceModelSpec.spectrumElementCount);
  final stft = MdxStft();
  var step = 0;
  for (var start = 0; start < paddedLength; start += _step) {
    final count = math.min(_chunk, paddedLength - start);
    for (var i = 0; i < _chunk; i++) {
      final index = start + i - _trim;
      chunk[i] = index >= 0 && index < mix.length ? mix[index] : 0;
    }
    stft.forward(chunk, chunk, spectrum);
    const dimF = OnDeviceModelSpec.dimF;
    const dimT = OnDeviceModelSpec.dimT;
    for (var channel = 0; channel < 4; channel++) {
      final offset = channel * dimF * dimT;
      spectrum.fillRange(offset, offset + 3 * dimT, 0);
    }
    _scaleTestSpectrum(spectrum, ++step);
    stft.inverse(spectrum, wave, right);
    for (var i = 0; i < count; i++) {
      final weight = count == 1
          ? 1.0
          : 0.5 - 0.5 * math.cos(2 * math.pi * i / (count - 1));
      acc[start + i] += wave[i] * weight;
      divider[start + i] += weight;
    }
  }
  final result = Float32List(mix.length);
  for (var i = 0; i < mix.length; i++) {
    final index = _trim + i;
    result[i] = divider[index] < 1e-8 ? 0 : acc[index] / divider[index];
  }
  return result;
}
