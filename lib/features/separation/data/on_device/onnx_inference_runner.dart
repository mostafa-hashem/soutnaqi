import 'dart:ffi' as ffi;
import 'dart:io';
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

_NativeSessionInfo _createNativeSession(
  String modelPath,
  int threads,
  int ortThreads,
  bool allowSpinning,
  bool useNnapi,
  int nnapiFlags,
) {
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
      >()(options, ortThreads),
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
    if (!is32Bit && OnnxInferenceRunner._useXnnpack) {
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

/// Owns one ORT session and two reusable, CPU-backed spectrogram tensors.
class OnnxInferenceRunner {
  OnnxInferenceRunner._(this._session) {
    try {
      _inputName.value = OnDeviceModelSpec.inputNodeName.toNativeUtf8().cast();
      _outputName.value = OnDeviceModelSpec.outputNodeName
          .toNativeUtf8()
          .cast();
      _initializeTensors();
    } catch (_) {
      dispose();
      rethrow;
    }
  }

  final ffi.Pointer<bg.OrtSession> _session;
  final _inputName = calloc<ffi.Pointer<ffi.Char>>();
  final _outputName = calloc<ffi.Pointer<ffi.Char>>();
  final _inputValue = calloc<ffi.Pointer<bg.OrtValue>>();
  final _outputValue = calloc<ffi.Pointer<bg.OrtValue>>();
  static const _elements = OnDeviceModelSpec.spectrumElementCount;
  final _inputData = calloc<ffi.Float>(_elements);
  final _outputData = calloc<ffi.Float>(_elements);
  late final Float32List input = _inputData.asTypedList(_elements);
  late final Float32List _output = _outputData.asTypedList(_elements);

  static const _maxIntraOpThreads = int.fromEnvironment(
    'MDX_THREADS',
    defaultValue: 4,
  );

  /// Opt-in spin-wait for benchmarking. Defaults off to avoid extra heat.
  static const _allowSpinning = bool.fromEnvironment('MDX_SPINNING');
  static const _useXnnpack = bool.fromEnvironment(
    'MDX_XNNPACK',
    defaultValue: true,
  );
  static const _ortThreads = int.fromEnvironment('MDX_ORT_THREADS');

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

  factory OnnxInferenceRunner.load(String modelPath) {
    final is32Bit = ffi.sizeOf<ffi.Pointer>() == 4;
    final maxThreads = _maxIntraOpThreads < 1 ? 1 : _maxIntraOpThreads;
    final threads = is32Bit
        ? 1
        : Platform.numberOfProcessors.clamp(1, maxThreads);
    final ortThreads = _ortThreads > 0
        ? _ortThreads.clamp(1, threads)
        : threads;
    final spinning = !is32Bit && _allowSpinning;
    final useNnapi = !is32Bit && Platform.isAndroid && _useNnapi;
    final nnapiFlags =
        (_nnapiFp16 ? NnapiFlags.useFp16.value : 0) |
        (_nnapiNchw ? NnapiFlags.useNCHW.value : 0) |
        (_nnapiCpuDisabled ? NnapiFlags.cpuDisabled.value : 0);

    final _NativeSessionInfo info;
    try {
      info = _createNativeSession(
        modelPath,
        threads,
        ortThreads,
        spinning,
        useNnapi,
        nnapiFlags,
      );
    } catch (error) {
      if (!useNnapi) rethrow;
      appLog.w(
        'ONNX NNAPI initialization failed, retrying on CPU',
        error: error,
      );
      return OnnxInferenceRunner._(
        ffi.Pointer.fromAddress(
          _createNativeSession(
            modelPath,
            threads,
            ortThreads,
            spinning,
            false,
            0,
          ).address,
        ),
      );
    }
    appLog.d(
      'ONNX session threads=$threads, xnnpack=${info.xnnpack}, nnapi=${info.nnapi}',
    );
    return OnnxInferenceRunner._(ffi.Pointer.fromAddress(info.address));
  }

  void _initializeTensors() {
    final api = OrtEnv.instance.ortApiPtr.ref;
    final memory = calloc<ffi.Pointer<bg.OrtMemoryInfo>>();
    final shape = calloc<ffi.Int64>(4);
    try {
      shape.asTypedList(4).setAll(0, const [
        1,
        4,
        OnDeviceModelSpec.dimF,
        OnDeviceModelSpec.dimT,
      ]);
      OrtStatus.checkOrtStatus(
        api.CreateCpuMemoryInfo.asFunction<
          bg.OrtStatusPtr Function(
            int,
            int,
            ffi.Pointer<ffi.Pointer<bg.OrtMemoryInfo>>,
          )
        >()(
          bg.OrtAllocatorType.OrtDeviceAllocator,
          bg.OrtMemType.OrtMemTypeDefault,
          memory,
        ),
      );
      final createTensor =
          api.CreateTensorWithDataAsOrtValue.asFunction<
            bg.OrtStatusPtr Function(
              ffi.Pointer<bg.OrtMemoryInfo>,
              ffi.Pointer<ffi.Void>,
              int,
              ffi.Pointer<ffi.Int64>,
              int,
              int,
              ffi.Pointer<ffi.Pointer<bg.OrtValue>>,
            )
          >();
      OrtStatus.checkOrtStatus(
        createTensor(
          memory.value,
          _inputData.cast(),
          _elements * 4,
          shape,
          4,
          ONNXTensorElementDataType.float.value,
          _inputValue,
        ),
      );
      OrtStatus.checkOrtStatus(
        createTensor(
          memory.value,
          _outputData.cast(),
          _elements * 4,
          shape,
          4,
          ONNXTensorElementDataType.float.value,
          _outputValue,
        ),
      );
    } finally {
      if (memory.value != ffi.nullptr) {
        api.ReleaseMemoryInfo.asFunction<
          void Function(ffi.Pointer<bg.OrtMemoryInfo>)
        >()(memory.value);
      }
      calloc.free(memory);
      calloc.free(shape);
    }
  }

  /// Runs on the worker. The caller owns the run options until this returns.
  Float32List runSpectrum(int runOptionsAddress) {
    final api = OrtEnv.instance.ortApiPtr.ref;
    OrtStatus.checkOrtStatus(
      api.Run.asFunction<
        bg.OrtStatusPtr Function(
          ffi.Pointer<bg.OrtSession>,
          ffi.Pointer<bg.OrtRunOptions>,
          ffi.Pointer<ffi.Pointer<ffi.Char>>,
          ffi.Pointer<ffi.Pointer<bg.OrtValue>>,
          int,
          ffi.Pointer<ffi.Pointer<ffi.Char>>,
          int,
          ffi.Pointer<ffi.Pointer<bg.OrtValue>>,
        )
      >()(
        _session,
        ffi.Pointer.fromAddress(runOptionsAddress),
        _inputName,
        _inputValue,
        1,
        _outputName,
        1,
        _outputValue,
      ),
    );
    return _output;
  }

  void dispose() {
    final api = OrtEnv.instance.ortApiPtr.ref;
    final releaseValue =
        api.ReleaseValue.asFunction<void Function(ffi.Pointer<bg.OrtValue>)>();
    if (_inputValue.value != ffi.nullptr) releaseValue(_inputValue.value);
    if (_outputValue.value != ffi.nullptr) releaseValue(_outputValue.value);
    api.ReleaseSession.asFunction<void Function(ffi.Pointer<bg.OrtSession>)>()(
      _session,
    );
    calloc.free(_inputName.value);
    calloc.free(_outputName.value);
    calloc.free(_inputName);
    calloc.free(_outputName);
    calloc.free(_inputValue);
    calloc.free(_outputValue);
    calloc.free(_inputData);
    calloc.free(_outputData);
  }
}
