import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:onnxruntime_v2/onnxruntime_v2.dart';
// ignore: implementation_imports — session config and tensor pointers are not public
import 'package:onnxruntime_v2/src/bindings/bindings.dart';
// ignore: implementation_imports
import 'package:onnxruntime_v2/src/bindings/onnxruntime_bindings_generated.dart'
    as bg;
import 'package:soutnaqi/core/logging/app_log.dart';
import 'package:soutnaqi/features/separation/data/on_device/audio_tensor_codec.dart';
import 'package:soutnaqi/features/separation/data/on_device/on_device_model_spec.dart';

/// Top-level so [Isolate.run] does not capture unsendable locals from callers.
Future<int> _loadNativeSessionInIsolate(String modelPath, int threads) {
  return Isolate.run(() => _createNativeSession(modelPath, threads));
}

/// Builds the native session off the UI isolate. Returns the session
/// pointer address; ownership transfers to the caller (do not release here).
///
/// Spinning is disabled and the worker count stays at one core so the UI
/// and the rest of the phone keep getting scheduled during HTDemucs.
int _createNativeSession(String modelPath, int threads) {
  OrtEnv.instance.init();
  final api = OrtEnv.instance.ortApiPtr.ref;

  final optionsPtrPtr = calloc<ffi.Pointer<bg.OrtSessionOptions>>();
  OrtStatus.checkOrtStatus(
    api.CreateSessionOptions.asFunction<
        bg.OrtStatusPtr Function(
          ffi.Pointer<ffi.Pointer<bg.OrtSessionOptions>>,
        )>()(optionsPtrPtr),
  );
  final options = optionsPtrPtr.value;
  calloc.free(optionsPtrPtr);

  try {
    OrtStatus.checkOrtStatus(
      api.SetIntraOpNumThreads.asFunction<
          bg.OrtStatusPtr Function(ffi.Pointer<bg.OrtSessionOptions>, int)>()(
        options,
        threads,
      ),
    );
    OrtStatus.checkOrtStatus(
      api.SetInterOpNumThreads.asFunction<
          bg.OrtStatusPtr Function(ffi.Pointer<bg.OrtSessionOptions>, int)>()(
        options,
        1,
      ),
    );
    OrtStatus.checkOrtStatus(
      api.SetSessionGraphOptimizationLevel.asFunction<
          bg.OrtStatusPtr Function(ffi.Pointer<bg.OrtSessionOptions>, int)>()(
        options,
        GraphOptimizationLevel.ortEnableAll.value,
      ),
    );
    _setSessionConfig(options, 'session.intra_op.allow_spinning', '0');
    _setSessionConfig(options, 'session.inter_op.allow_spinning', '0');
    _appendXnnpack(options, threads);
    OrtStatus.checkOrtStatus(
      onnxRuntimeBinding.OrtSessionOptionsAppendExecutionProvider_CPU(
        options,
        CPUFlags.useArena.value,
      ),
    );

    final sessionPtrPtr = calloc<ffi.Pointer<bg.OrtSession>>();
    final pathPtr = modelPath.toNativeUtf8().cast<ffi.Char>();
    try {
      OrtStatus.checkOrtStatus(
        api.CreateSession.asFunction<
            bg.OrtStatusPtr Function(
              ffi.Pointer<bg.OrtEnv>,
              ffi.Pointer<ffi.Char>,
              ffi.Pointer<bg.OrtSessionOptions>,
              ffi.Pointer<ffi.Pointer<bg.OrtSession>>,
            )>()(OrtEnv.instance.ptr, pathPtr, options, sessionPtrPtr),
      );
      return sessionPtrPtr.value.address;
    } finally {
      calloc.free(pathPtr);
      calloc.free(sessionPtrPtr);
    }
  } finally {
    api.ReleaseSessionOptions.asFunction<
        void Function(ffi.Pointer<bg.OrtSessionOptions>)>()(options);
  }
}

void _setSessionConfig(
  ffi.Pointer<bg.OrtSessionOptions> options,
  String key,
  String value,
) {
  final keyPtr = key.toNativeUtf8().cast<ffi.Char>();
  final valuePtr = value.toNativeUtf8().cast<ffi.Char>();
  try {
    OrtStatus.checkOrtStatus(
      OrtEnv.instance.ortApiPtr.ref.AddSessionConfigEntry.asFunction<
          bg.OrtStatusPtr Function(
            ffi.Pointer<bg.OrtSessionOptions>,
            ffi.Pointer<ffi.Char>,
            ffi.Pointer<ffi.Char>,
          )>()(options, keyPtr, valuePtr),
    );
  } finally {
    calloc.free(keyPtr);
    calloc.free(valuePtr);
  }
}

void _appendXnnpack(ffi.Pointer<bg.OrtSessionOptions> options, int threads) {
  final providerNamePtr = 'XNNPACK'.toNativeUtf8().cast<ffi.Char>();
  final keyPtr = 'intra_op_num_threads'.toNativeUtf8().cast<ffi.Char>();
  final valuePtr = '$threads'.toNativeUtf8().cast<ffi.Char>();
  final keyPtrPtr = calloc<ffi.Pointer<ffi.Char>>();
  final valuePtrPtr = calloc<ffi.Pointer<ffi.Char>>();
  keyPtrPtr[0] = keyPtr;
  valuePtrPtr[0] = valuePtr;
  try {
    OrtStatus.checkOrtStatus(
      OrtEnv.instance.ortApiPtr.ref.SessionOptionsAppendExecutionProvider
          .asFunction<
              bg.OrtStatusPtr Function(
                ffi.Pointer<bg.OrtSessionOptions>,
                ffi.Pointer<ffi.Char>,
                ffi.Pointer<ffi.Pointer<ffi.Char>>,
                ffi.Pointer<ffi.Pointer<ffi.Char>>,
                int,
              )>()(options, providerNamePtr, keyPtrPtr, valuePtrPtr, 1),
    );
  } finally {
    calloc.free(providerNamePtr);
    calloc.free(keyPtr);
    calloc.free(valuePtr);
    calloc.free(keyPtrPtr);
    calloc.free(valuePtrPtr);
  }
}

/// Owns a single ONNX Runtime session for one `separate()` call and runs
/// model-sized chunks through it. `OrtSession.runAsync` uses the plugin's
/// own persistent background isolate, so inference never blocks the UI
/// thread.
///
/// HTDemucs runs poorly on NNAPI (STFT / attention fall back to CPU with
/// extra boundary copies), so the session prefers XNNPACK + CPU instead of
/// [OrtSessionOptions.appendDefaultProviders].
class OnnxInferenceRunner {
  OnnxInferenceRunner._(this._session);

  final OrtSession _session;
  static bool _envInitialized = false;

  /// One core only. Extra workers plus spin-wait freeze the whole phone.
  static const _maxIntraOpThreads = 1;

  /// One HTDemucs chunk can exceed the plugin's default 60s isolate timeout.
  static const _chunkTimeout = Duration(minutes: 10);

  static Future<OnnxInferenceRunner> load(String modelPath) async {
    if (!_envInitialized) {
      OrtEnv.instance.init();
      _envInitialized = true;
    }
    final threads =
        Platform.numberOfProcessors.clamp(1, _maxIntraOpThreads);
    // CreateSession + graph opt on a 165MB model is multi-second sync work —
    // never do it on the UI isolate or Android reports ANR.
    final sessionAddress =
        await _loadNativeSessionInIsolate(modelPath, threads);
    appLog.d(
      '⚡ On-device ONNX session: XNNPACK+CPU, intraOp=$threads, spinning=off',
    );
    return OnnxInferenceRunner._(OrtSession.fromAddress(sessionAddress));
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
    OrtValueTensor? outputTensor;
    final stopwatch = Stopwatch()..start();
    try {
      final outputs = await _session.runAsyncWithTimeout(
        runOptions,
        {OnDeviceModelSpec.inputNodeName: inputTensor},
        _chunkTimeout,
        [OnDeviceModelSpec.outputNodeName],
      );
      outputTensor = outputs?.first as OrtValueTensor?;
      if (outputTensor == null) {
        throw StateError('On-device model produced no output');
      }
      // Yield once so the UI can paint progress before the bulk copy.
      await Future<void>.delayed(Duration.zero);
      final stems = _copyStemsFromTensor(outputTensor);
      stopwatch.stop();
      appLog.d('⚡ On-device chunk inference ${stopwatch.elapsedMilliseconds}ms');
      return stems;
    } finally {
      inputTensor.release();
      outputTensor?.release();
      runOptions.release();
    }
  }

  /// Bulk-copies float32 stem data from native memory instead of walking
  /// `tensor.value` (which builds nested `List<num>` element-by-element).
  static List<List<Float32List>> _copyStemsFromTensor(OrtValueTensor tensor) {
    final sourceCount = OnDeviceModelSpec.sources.length;
    const channelCount = OnDeviceModelSpec.channels;
    const samples = OnDeviceModelSpec.chunkSamples;
    final elementCount = sourceCount * channelCount * samples;

    final dataPtrPtr = calloc<ffi.Pointer<ffi.Float>>();
    try {
      final statusPtr = OrtEnv.instance.ortApiPtr.ref.GetTensorMutableData
          .asFunction<
              bg.OrtStatusPtr Function(
                ffi.Pointer<bg.OrtValue>,
                ffi.Pointer<ffi.Pointer<ffi.Void>>,
              )>()(
        ffi.Pointer<bg.OrtValue>.fromAddress(tensor.address),
        dataPtrPtr.cast(),
      );
      OrtStatus.checkOrtStatus(statusPtr);

      final view = dataPtrPtr.value.asTypedList(elementCount);
      return List.generate(sourceCount, (s) {
        return List.generate(channelCount, (c) {
          final channel = Float32List(samples);
          final start = (s * channelCount + c) * samples;
          channel.setRange(0, samples, view, start);
          return channel;
        });
      });
    } finally {
      calloc.free(dataPtrPtr);
    }
  }

  Future<void> dispose() async {
    await _session.release();
  }
}
