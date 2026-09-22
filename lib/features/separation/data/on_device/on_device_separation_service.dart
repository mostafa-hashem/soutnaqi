import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:soutnaqi/core/config/app_env.dart';
import 'package:soutnaqi/core/errors/app_exception.dart';
import 'package:soutnaqi/core/logging/app_log.dart';
import 'package:soutnaqi/features/separation/data/on_device/audio_tensor_codec.dart';
import 'package:soutnaqi/features/separation/data/on_device/demucs_chunker.dart';
import 'package:soutnaqi/features/separation/data/on_device/on_device_model_repository.dart';
import 'package:soutnaqi/features/separation/data/on_device/on_device_model_spec.dart';
import 'package:soutnaqi/features/separation/data/on_device/on_device_separation_engine.dart';
import 'package:soutnaqi/features/separation/data/separation_audio_io.dart';
import 'package:soutnaqi/features/separation/data/separation_cancel_token.dart';
import 'package:soutnaqi/features/separation/data/separation_progress.dart';
import 'package:soutnaqi/features/separation/data/separation_service.dart';
import 'package:soutnaqi/features/separation/data/separation_target.dart';
import 'package:uuid/uuid.dart';

SeparationService createOnDeviceSeparationService() =>
    OnDeviceSeparationService();

Future<void> warmUpOnDeviceSeparationIfReady() =>
    OnDeviceSeparationEngine.instance.warmUpInBackgroundIfReady();

/// Top-level isolate entry points — must not close over [separate]'s locals
/// (`onProgress` → WorkspaceCubit → AudioPlayer is unsendable).
Future<StereoSamples> _decodeWavInIsolate(String path) {
  return Isolate.run(() => AudioTensorCodec.decodeWav(path));
}

Future<void> _encodeWavInIsolate(String outputPath, StereoSamples samples) {
  return Isolate.run(
    () => AudioTensorCodec.encodeWav(outputPath: outputPath, samples: samples),
  );
}

Future<StereoSamples> _subtractVocalsInIsolate(
  StereoSamples mix,
  StereoSamples vocals,
) {
  return Isolate.run(() => _subtractVocals(mix: mix, vocals: vocals));
}

StereoSamples _subtractVocals({
  required StereoSamples mix,
  required StereoSamples vocals,
}) {
  final length = mix.length;
  final left = Float32List(length);
  final right = Float32List(length);
  for (var i = 0; i < length; i++) {
    left[i] = mix.left[i] - vocals.left[i];
    right[i] = mix.right[i] - vocals.right[i];
  }
  return StereoSamples(left: left, right: right);
}

/// Fully offline separation via a Demucs model exported to ONNX
/// (see [OnDeviceModelSpec]). No server, no per-request network call — the
/// model is downloaded once and cached by [OnDeviceModelRepository].
class OnDeviceSeparationService implements SeparationService {
  OnDeviceSeparationService({OnDeviceModelRepository? modelRepository})
      : _modelRepository = modelRepository ?? OnDeviceModelRepository();

  static const _uuid = Uuid();

  final OnDeviceModelRepository _modelRepository;
  final OnDeviceSeparationEngine _engine = OnDeviceSeparationEngine.instance;

  @override
  bool get isSupported => AppEnv.isOnDeviceSeparationSupported;

  @override
  Future<String> separate({
    required String inputAudioPath,
    required SeparationTarget target,
    SeparationProgressCallback? onProgress,
    SeparationCancelToken? cancelToken,
  }) async {
    if (!isSupported) {
      throw const AppException(messageKey: 'separationNotConfigured');
    }

    appLog.d('⚡ Starting on-device Demucs separation: $target');
    var preparedPath = inputAudioPath;
    try {
      cancelToken?.throwIfCancelled();
      onProgress?.call(
        const SeparationProgress(stage: SeparationStage.preparingAudio),
      );
      preparedPath = await SeparationAudioIo.prepareWavInput(inputAudioPath);
      cancelToken?.throwIfCancelled();

      if (!await _modelRepository.isModelCached()) {
        throw const AppException(messageKey: 'separationModelRequired');
      }

      onProgress?.call(
        const SeparationProgress(stage: SeparationStage.preparingAudio, progress: 1),
      );
      final mix = await _decodeWavInIsolate(preparedPath);
      cancelToken?.throwIfCancelled();

      final runner = await _engine.ensureRunner(onProgress: onProgress);
      cancelToken?.throwIfCancelled();

      final stems = await DemucsChunker.process(
        mix: mix,
        runChunk: runner.runChunk,
        cancelToken: cancelToken,
        onProgress: (chunkIndex, totalChunks) {
          onProgress?.call(
            SeparationProgress(
              stage: SeparationStage.separating,
              progress: chunkIndex / totalChunks,
              chunkIndex: chunkIndex,
              totalChunks: totalChunks,
            ),
          );
        },
      );

      cancelToken?.throwIfCancelled();

      final vocals = stems[OnDeviceModelSpec.vocalsStemIndex];
      final targetSamples = target == SeparationTarget.vocals
          ? vocals
          : await _subtractVocalsInIsolate(mix, vocals);

      onProgress?.call(
        const SeparationProgress(stage: SeparationStage.encodingOutput),
      );
      final directory = await getTemporaryDirectory();
      final wavOutput = '${directory.path}/soutnaqi_${_uuid.v4()}.wav';
      await _encodeWavInIsolate(wavOutput, targetSamples);
      cancelToken?.throwIfCancelled();

      final outputPath = await SeparationAudioIo.encodeWavToM4a(wavOutput);
      appLog.d('✅ On-device separation complete: $outputPath');
      return outputPath;
    } on AppException {
      rethrow;
    } catch (error) {
      appLog.e('❌ On-device separation failed', error: error);
      throw AppException(messageKey: 'separationFailed', cause: error);
    } finally {
      if (preparedPath != inputAudioPath) {
        try {
          await File(preparedPath).delete();
        } catch (_) {}
      }
    }
  }
}
