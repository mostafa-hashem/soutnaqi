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
import 'package:soutnaqi/features/separation/data/on_device/on_device_model_spec.dart';

typedef _NativeSessionInfo = ({int address, bool xnnpack, bool nnapi});

/// Top-level so [Isolate.run] does not capture unsendable locals from callers.
Future<_NativeSessionInfo> _loadNativeSessionInIsolate(
  String modelPath,
  int threads,
  bool allowSpinning,
  bool useNnapi,
  int nnapiFlags,
) {
  return Isolate.run(() {
    try {
      return _createNativeSession(
        modelPath,
        threads,
        allowSpinning,
        useNnapi,
        nnapiFlags,
      );
    } catch (e) {
      // Must not propagate private _OrtException across isolate boundary.
      throw Exception('Failed to load ONNX native session: $e');
    }
  });
}

/// Builds the native session off the UI isolate. Returns the session
/// pointer address; ownership transfers to the caller (do not release here).
///
/// XNNPACK/CPU workers use the big cores. Spinning is opt-in because it
/// keeps cores busy between operators and can increase heat on phones.
_NativeSessionInfo _createNativeSession(
  String modelPath,
  int threads,
  bool allowSpinning,
  bool useNnapi,
  int nnapiFlags,
) {
  OrtEnv.instance.init();
  final api = OrtEnv.instance.ortApiPtr.ref;

  final optionsPtrPtr = calloc<ffi.Pointer<bg.OrtSessionOptions>>();
  OrtStatus.checkOrtStatus(
    api.CreateSessionOptions.asFunction<
      bg.OrtStatusPtr Function(ffi.Pointer<ffi.Pointer<bg.OrtSessionOptions>>)
    >()(optionsPtrPtr),
  );
  final options = optionsPtrPtr.value;
  calloc.free(optionsPtrPtr);

  try {
    OrtStatus.checkOrtStatus(
      api.SetIntraOpNumThreads.asFunction<
        bg.OrtStatusPtr Function(ffi.Pointer<bg.OrtSessionOptions>, int)
      >()(options, threads),
    );
    OrtStatus.checkOrtStatus(
      api.SetInterOpNumThreads.asFunction<
        bg.OrtStatusPtr Function(ffi.Pointer<bg.OrtSessionOptions>, int)
      >()(options, 1),
    );
    OrtStatus.checkOrtStatus(
      api.SetSessionGraphOptimizationLevel.asFunction<
        bg.OrtStatusPtr Function(ffi.Pointer<bg.OrtSessionOptions>, int)
      >()(options, GraphOptimizationLevel.ortEnableAll.value),
    );
    final spinning = allowSpinning ? '1' : '0';
    _setSessionConfig(options, 'session.intra_op.allow_spinning', spinning);
    _setSessionConfig(options, 'session.inter_op.allow_spinning', spinning);

    var nnapi = false;
    if (useNnapi) {
      try {
        _appendNnapi(options, nnapiFlags);
        nnapi = true;
      } catch (_) {
        // Keep the CPU/XNNPACK path usable when NNAPI is unavailable.
      }
    }

    // On 32-bit architectures (e.g. armeabi-v7a), XNNPACK can deadlock worker
    // threads or crash on unaligned memory access (SIGBUS). Use CPU provider
    // directly on 32-bit, and safely attempt XNNPACK on 64-bit devices with fallback.
    final is32Bit = ffi.sizeOf<ffi.Pointer>() == 4;
    var xnnpack = false;
    if (!is32Bit) {
      try {
        _appendXnnpack(options, threads);
        xnnpack = true;
      } catch (_) {
        // Fall back cleanly to CPU provider
      }
    }

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
          )
        >()(OrtEnv.instance.ptr, pathPtr, options, sessionPtrPtr),
      );
      return (
        address: sessionPtrPtr.value.address,
        xnnpack: xnnpack,
        nnapi: nnapi,
      );
    } finally {
      calloc.free(pathPtr);
      calloc.free(sessionPtrPtr);
    }
  } finally {
    api.ReleaseSessionOptions.asFunction<
      void Function(ffi.Pointer<bg.OrtSessionOptions>)
    >()(options);
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
      OrtEnv.instance.ortApiPtr.ref.AddSessionConfigEntry
          .asFunction<
            bg.OrtStatusPtr Function(
              ffi.Pointer<bg.OrtSessionOptions>,
              ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Char>,
            )
          >()(options, keyPtr, valuePtr),
    );
  } finally {
    calloc.free(keyPtr);
    calloc.free(valuePtr);
  }
}

void _appendNnapi(ffi.Pointer<bg.OrtSessionOptions> options, int flags) {
  OrtStatus.checkOrtStatus(
    onnxRuntimeBinding.OrtSessionOptionsAppendExecutionProvider_Nnapi(
      options,
      flags,
    ),
  );
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
            )
          >()(options, providerNamePtr, keyPtrPtr, valuePtrPtr, 1),
    );
  } finally {
    calloc.free(providerNamePtr);
    calloc.free(keyPtr);
    calloc.free(valuePtr);
    calloc.free(keyPtrPtr);
    calloc.free(valuePtrPtr);
  }
}

/// Owns a single ONNX Runtime session and runs model-sized chunks through it.
/// `runAsyncWithTimeout` reuses the plugin's persistent background isolate,
/// so inference never blocks the UI thread after the first chunk.
///
/// The Dimensity 8200 Ultra has four big A78 cores, so four workers give a
/// large speedup without waking the little cores. Spinning is opt-in via
/// `--dart-define=MDX_SPINNING=true`; it can help latency but increases heat.
class OnnxInferenceRunner {
  OnnxInferenceRunner._(this._session);

  final OrtSession _session;
  static bool _envInitialized = false;

  /// Four big cores. Override with `--dart-define=MDX_THREADS=N` for A/B tests.
  static const _maxIntraOpThreads = int.fromEnvironment(
    'MDX_THREADS',
    defaultValue: 4,
  );

  /// Opt-in spin-wait for benchmarking. Defaults off to avoid extra heat.
  static const _allowSpinning = bool.fromEnvironment('MDX_SPINNING');

  /// NNAPI is opt-in: it can use the Dimensity APU/GPU, but some models fall
  /// back to NNAPI's slow CPU implementation. A/B it per device.
  static const _useNnapi = bool.fromEnvironment('MDX_NNAPI');
  static const _nnapiFp16 = bool.fromEnvironment(
    'MDX_NNAPI_FP16',
    defaultValue: true,
  );
  static const _nnapiNchw = bool.fromEnvironment('MDX_NNAPI_NCHW');
  static const _nnapiCpuDisabled = bool.fromEnvironment(
    'MDX_NNAPI_CPU_DISABLED',
    defaultValue: true,
  );

  /// One chunk timeout. Reduced to 90 seconds so worker hangs fail fast with actionable error.
  static const _chunkTimeout = Duration(seconds: 90);

  static Future<OnnxInferenceRunner> load(String modelPath) async {
    if (!_envInitialized) {
      OrtEnv.instance.init();
      _envInitialized = true;
    }
    final is32Bit = ffi.sizeOf<ffi.Pointer>() == 4;
    final threads = is32Bit
        ? 1
        : Platform.numberOfProcessors.clamp(1, _maxIntraOpThreads);
    final spinning = !is32Bit && _allowSpinning;
    final nnapiFlags =
        (_nnapiFp16 ? NnapiFlags.useFp16.value : 0) |
        (_nnapiNchw ? NnapiFlags.useNCHW.value : 0) |
        (_nnapiCpuDisabled ? NnapiFlags.cpuDisabled.value : 0);

    try {
      final providers = OrtEnv.instance.availableProviders();
      appLog.d('⚡ ORT providers: ${providers.map((p) => p.name).join(', ')}');
    } catch (_) {
      // Provider introspection is best-effort.
    }

    // CreateSession is multi-second sync work — never do it on the UI
    // isolate or Android reports ANR.
    _NativeSessionInfo info;
    try {
      info = await _loadNativeSessionInIsolate(
        modelPath,
        threads,
        spinning,
        !is32Bit && _useNnapi,
        nnapiFlags,
      );
    } catch (error) {
      if (!_useNnapi) rethrow;
      appLog.w(
        '⚡ NNAPI session failed; retrying with CPU/XNNPACK only',
        error: error,
      );
      info = await _loadNativeSessionInIsolate(
        modelPath,
        threads,
        spinning,
        false,
        0,
      );
    }
    appLog.d(
      '⚡ On-device ONNX session: is32Bit=$is32Bit, intraOp=$threads, '
      'spinning=$spinning, xnnpack=${info.xnnpack}, nnapi=${info.nnapi}',
    );
    return OnnxInferenceRunner._(OrtSession.fromAddress(info.address));
  }

  /// Runs one spectrogram and returns the model's spectrum, same length as
  /// [spectrum] (`[1, 4, dimF, dimT]` packed row-major).
  Future<Float32List> runSpectrum(Float32List spectrum) async {
    final inputTensor = OrtValueTensor.createTensorWithDataList(
      spectrum,
      const [1, 4, OnDeviceModelSpec.dimF, OnDeviceModelSpec.dimT],
    );
    final runOptions = OrtRunOptions();
    OrtValueTensor? outputTensor;
    final stopwatch = Stopwatch()..start();
    try {
      final future = _session.runAsyncWithTimeout(
        runOptions,
        {OnDeviceModelSpec.inputNodeName: inputTensor},
        _chunkTimeout,
        const [OnDeviceModelSpec.outputNodeName],
      );
      if (future == null) {
        throw StateError('On-device model session is not available');
      }
      final outputs = await future;
      outputTensor = outputs.isNotEmpty
          ? outputs.first as OrtValueTensor?
          : null;
      if (outputTensor == null) {
        throw StateError('On-device model produced no output');
      }
      await Future<void>.delayed(Duration.zero);
      final predicted = _copyFloats(
        outputTensor,
        OnDeviceModelSpec.spectrumElementCount,
      );
      stopwatch.stop();
      appLog.d(
        '⚡ On-device chunk inference ${stopwatch.elapsedMilliseconds}ms',
      );
      return predicted;
    } finally {
      inputTensor.release();
      outputTensor?.release();
      runOptions.release();
    }
  }

  static Float32List _copyFloats(OrtValueTensor tensor, int elementCount) {
    final dataPtrPtr = calloc<ffi.Pointer<ffi.Float>>();
    try {
      final statusPtr =
          OrtEnv.instance.ortApiPtr.ref.GetTensorMutableData
              .asFunction<
                bg.OrtStatusPtr Function(
                  ffi.Pointer<bg.OrtValue>,
                  ffi.Pointer<ffi.Pointer<ffi.Void>>,
                )
              >()(
            ffi.Pointer<bg.OrtValue>.fromAddress(tensor.address),
            dataPtrPtr.cast(),
          );
      OrtStatus.checkOrtStatus(statusPtr);
      final copy = Float32List(elementCount);
      copy.setRange(
        0,
        elementCount,
        dataPtrPtr.value.asTypedList(elementCount),
      );
      return copy;
    } finally {
      calloc.free(dataPtrPtr);
    }
  }

  Future<void> dispose() async {
    try {
      await _session.killAllIsolates();
    } catch (_) {}
    await _session.release();
  }
}
