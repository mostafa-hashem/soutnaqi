import 'dart:typed_data';

import 'package:soutnaqi/core/config/app_env.dart';
import 'package:soutnaqi/core/logging/app_log.dart';
import 'package:soutnaqi/features/separation/data/on_device/audio_tensor_codec.dart';
import 'package:soutnaqi/features/separation/data/on_device/on_device_model_repository.dart';
import 'package:soutnaqi/features/separation/data/on_device/on_device_model_spec.dart';
import 'package:soutnaqi/features/separation/data/on_device/onnx_inference_runner.dart';
import 'package:soutnaqi/features/separation/data/separation_progress.dart';

/// Shared ONNX session for on-device separation. Caches the compiled session
/// and pays the one-time NNAPI warm-up cost ahead of the user's first
/// separation when possible.
class OnDeviceSeparationEngine {
  OnDeviceSeparationEngine._();

  static final OnDeviceSeparationEngine instance = OnDeviceSeparationEngine._();

  final OnDeviceModelRepository _modelRepository = OnDeviceModelRepository();

  OnnxInferenceRunner? _runner;
  Future<void>? _warmUpTask;
  bool _isWarmedUp = false;

  bool get isWarmedUp => _isWarmedUp;

  Future<void> warmUpInBackgroundIfReady() {
    if (!AppEnv.isOnDeviceSeparationSupported) {
      return Future<void>.value();
    }
    return warmUpIfNeeded();
  }

  Future<void> warmUpIfNeeded({SeparationProgressCallback? onProgress}) async {
    if (_isWarmedUp && _runner != null) return;
    if (_warmUpTask != null) {
      await _warmUpTask;
      return;
    }

    _warmUpTask = _warmUp(onProgress: onProgress);
    try {
      await _warmUpTask;
    } finally {
      _warmUpTask = null;
    }
  }

  Future<OnnxInferenceRunner> ensureRunner({
    SeparationProgressCallback? onProgress,
  }) async {
    await warmUpIfNeeded(onProgress: onProgress);
    final runner = _runner;
    if (runner == null) {
      throw StateError('On-device separation engine is not ready');
    }
    return runner;
  }

  Future<void> _warmUp({SeparationProgressCallback? onProgress}) async {
    if (!await _modelRepository.isModelCached()) return;

    onProgress?.call(
      const SeparationProgress(
        stage: SeparationStage.warmingUpEngine,
        progress: 0,
      ),
    );

    appLog.d('🔍 Warming up on-device separation engine…');
    final runner = _runner ??=
        await OnnxInferenceRunner.load(await _modelRepository.modelPath());

    final silentLeft = Float32List(OnDeviceModelSpec.chunkSamples);
    final silentRight = Float32List(OnDeviceModelSpec.chunkSamples);
    await runner.runChunk(
      StereoSamples(left: silentLeft, right: silentRight),
    );

    _isWarmedUp = true;
    appLog.d('✅ On-device separation engine ready');
    onProgress?.call(
      const SeparationProgress(
        stage: SeparationStage.warmingUpEngine,
        progress: 1,
      ),
    );
  }

  Future<void> dispose() async {
    final runner = _runner;
    _runner = null;
    _isWarmedUp = false;
    if (runner != null) {
      await runner.dispose();
    }
  }
}
