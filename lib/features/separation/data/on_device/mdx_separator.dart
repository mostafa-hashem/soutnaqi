import 'dart:math' as math;
import 'dart:typed_data';

import 'package:soutnaqi/core/logging/app_log.dart';
import 'package:soutnaqi/features/separation/data/on_device/mdx_stft.dart';
import 'package:soutnaqi/features/separation/data/on_device/on_device_model_spec.dart';
import 'package:soutnaqi/features/separation/data/separation_cancel_token.dart';
import 'package:soutnaqi/features/separation/data/separation_target.dart';

typedef ReadStereoFrames =
    Future<void> Function(
      Float32List left,
      Float32List right,
      int offset,
      int count,
    );
typedef WriteStereoFrames =
    Future<void> Function(Float32List left, Float32List right, int count);

/// UVR's center padding and 25% Hann overlap-add with window-sized buffers.
class MdxSeparator {
  MdxSeparator._();

  static final _fullChunkWindow = _hann(OnDeviceModelSpec.chunkSamples);

  static Future<void> separate({
    required int frameCount,
    required ReadStereoFrames readFrames,
    required WriteStereoFrames writeFrames,
    required SeparationTarget target,
    required Float32List spectrum,
    required Float32List Function() runSpectrum,
    void Function(int chunkIndex, int totalChunks)? onProgress,
    SeparationCancelToken? cancelToken,
  }) async {
    if (frameCount <= 0) throw ArgumentError.value(frameCount, 'frameCount');
    const trim = OnDeviceModelSpec.trimSamples;
    const chunk = OnDeviceModelSpec.chunkSamples;
    const step = OnDeviceModelSpec.strideSamples;
    const overlap = chunk - step;
    const genSize = OnDeviceModelSpec.genSize;
    final end = trim + frameCount;
    final paddedEnd = end + genSize + trim - frameCount % genSize;
    // A window starting outside the retained signal cannot affect its output.
    final totalChunks = (end + step - 1) ~/ step;

    final transform = MdxStft();
    final chunkLeft = Float32List(chunk);
    final chunkRight = Float32List(chunk);
    final waveLeft = Float32List(chunk);
    final waveRight = Float32List(chunk);
    final accLeft = Float32List(chunk);
    final accRight = Float32List(chunk);
    final divider = Float32List(chunk);

    final readTime = Stopwatch();
    final forwardTime = Stopwatch();
    final inferenceTime = Stopwatch();
    final inverseTime = Stopwatch();
    final overlapTime = Stopwatch();
    final writeTime = Stopwatch();

    onProgress?.call(0, totalChunks);
    for (var index = 0; index < totalChunks; index++) {
      cancelToken?.throwIfCancelled();
      final start = index * step;
      final keep = index == 0 ? 0 : overlap;
      final firstNewFrame = math.max(start + keep, trim);
      final lastNewFrame = math.min(start + chunk, end);
      if (lastNewFrame > firstNewFrame) {
        readTime.start();
        await readFrames(
          chunkLeft,
          chunkRight,
          firstNewFrame - start,
          lastNewFrame - firstNewFrame,
        );
        readTime.stop();
      }
      cancelToken?.throwIfCancelled();

      forwardTime.start();
      transform.forward(chunkLeft, chunkRight, spectrum);
      _zeroLowBins(spectrum);
      forwardTime.stop();

      inferenceTime.start();
      final predicted = runSpectrum();
      inferenceTime.stop();
      cancelToken?.throwIfCancelled();

      inverseTime.start();
      transform.inverse(predicted, waveLeft, waveRight);
      inverseTime.stop();

      overlapTime.start();
      final actual = math.min(chunk, paddedEnd - start);
      final window = actual == chunk ? _fullChunkWindow : _hann(actual);
      // Samples outside the requested output never contribute a divisor.
      final localStart = math.max(0, trim - start);
      final localEnd = math.min(actual, end - start);
      for (var i = localStart; i < localEnd; i++) {
        final weight = window[i];
        accLeft[i] += waveLeft[i] * weight;
        accRight[i] += waveRight[i] * weight;
        divider[i] += weight;
      }
      final finish = math.min(step, localEnd);
      for (var i = localStart; i < finish; i++) {
        final weight = divider[i];
        final scale = weight < 1e-8 ? 0 : 1 / weight;
        final offset = i - localStart;
        waveLeft[offset] = accLeft[i] * scale;
        waveRight[offset] = accRight[i] * scale;
        if (target == SeparationTarget.instrumental) {
          const gain = OnDeviceModelSpec.compensate;
          waveLeft[offset] = chunkLeft[i] - waveLeft[offset] * gain;
          waveRight[offset] = chunkRight[i] - waveRight[offset] * gain;
        }
      }
      _retainOverlap(chunkLeft, step, overlap);
      _retainOverlap(chunkRight, step, overlap);
      _retainOverlap(accLeft, step, overlap);
      _retainOverlap(accRight, step, overlap);
      _retainOverlap(divider, step, overlap);
      overlapTime.stop();

      writeTime.start();
      await writeFrames(waveLeft, waveRight, finish - localStart);
      writeTime.stop();
      cancelToken?.throwIfCancelled();
      onProgress?.call(index + 1, totalChunks);
    }
    appLog.d(
      'MDX chunks=$totalChunks, read=${readTime.elapsedMilliseconds}ms, '
      'STFT=${forwardTime.elapsedMilliseconds}ms, ORT=${inferenceTime.elapsedMilliseconds}ms, '
      'ISTFT=${inverseTime.elapsedMilliseconds}ms, overlap=${overlapTime.elapsedMilliseconds}ms, '
      'write=${writeTime.elapsedMilliseconds}ms',
    );
  }

  static void _retainOverlap(Float32List buffer, int step, int overlap) {
    buffer.setRange(0, overlap, buffer, step);
    buffer.fillRange(overlap, buffer.length, 0);
  }

  static void _zeroLowBins(Float32List spectrum) {
    const dimF = OnDeviceModelSpec.dimF;
    const dimT = OnDeviceModelSpec.dimT;
    for (var channel = 0; channel < 4; channel++) {
      final start = channel * dimF * dimT;
      spectrum.fillRange(start, start + 3 * dimT, 0);
    }
  }

  static Float64List _hann(int length) {
    if (length <= 1) return Float64List(length)..fillRange(0, length, 1);
    return Float64List.fromList(
      List.generate(
        length,
        (i) => 0.5 - 0.5 * math.cos(2 * math.pi * i / (length - 1)),
      ),
    );
  }
}
