import 'dart:io';
import 'dart:typed_data';

import 'package:onnxruntime_v2/onnxruntime_v2.dart';
import 'package:soutnaqi/features/separation/data/on_device/audio_tensor_codec.dart';
import 'package:soutnaqi/features/separation/data/on_device/on_device_model_spec.dart';

/// Owns a single ONNX Runtime session for one `separate()` call and runs
/// model-sized chunks through it. `OrtSession.runAsync` uses the plugin's
/// own persistent background isolate, so inference never blocks the UI
/// thread.
class OnnxInferenceRunner {
  OnnxInferenceRunner._(this._session);

  final OrtSession _session;
  static bool _envInitialized = false;

  static Future<OnnxInferenceRunner> load(String modelPath) async {
    if (!_envInitialized) {
      OrtEnv.instance.init();
      _envInitialized = true;
    }
    final options = OrtSessionOptions();
    await options.appendDefaultProviders();
    final session = OrtSession.fromFile(File(modelPath), options);
    return OnnxInferenceRunner._(session);
  }

  /// Runs one model-sized stereo chunk and returns the stem output shaped
  /// `[source][channel][sample]`, source order matching
  /// [OnDeviceModelSpec.sources].
  Future<List<List<Float32List>>> runChunk(StereoSamples chunk) async {
    final planar = Float32List(OnDeviceModelSpec.channels * chunk.length);
    planar.setRange(0, chunk.length, chunk.left);
    planar.setRange(chunk.length, chunk.length * 2, chunk.right);

    final inputTensor = OrtValueTensor.createTensorWithDataList(
      planar,
      [1, OnDeviceModelSpec.channels, chunk.length],
    );
    final runOptions = OrtRunOptions();
    try {
      final outputs = await _session.runAsync(
        runOptions,
        {OnDeviceModelSpec.inputNodeName: inputTensor},
        [OnDeviceModelSpec.outputNodeName],
      );
      final tensor = outputs?.first as OrtValueTensor?;
      final value = tensor?.value;
      if (value is! List || value.isEmpty) {
        throw StateError('On-device model produced no output');
      }
      // value shape: [batch=1][source][channel][sample].
      final sources = value[0] as List;
      return List.generate(sources.length, (s) {
        final channels = sources[s] as List;
        return List.generate(channels.length, (c) {
          final samples = channels[c] as List;
          return Float32List.fromList(samples.cast<double>());
        });
      });
    } finally {
      inputTensor.release();
      runOptions.release();
    }
  }

  Future<void> dispose() async {
    await _session.release();
  }
}
