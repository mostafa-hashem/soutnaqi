import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:onnxruntime_v2/onnxruntime_v2.dart';
import 'package:soutnaqi/core/errors/app_exception.dart';
import 'package:soutnaqi/core/logging/app_log.dart';
import 'package:soutnaqi/features/separation/data/on_device/mdx_pcm_io.dart';
import 'package:soutnaqi/features/separation/data/on_device/mdx_separator.dart';
import 'package:soutnaqi/features/separation/data/on_device/onnx_inference_runner.dart';
import 'package:soutnaqi/features/separation/data/separation_cancel_token.dart';
import 'package:soutnaqi/features/separation/data/separation_progress.dart';
import 'package:soutnaqi/features/separation/data/separation_target.dart';

/// Reuses one isolate and ONNX session while keeping native runs serial.
class OnDeviceSeparationEngine {
  OnDeviceSeparationEngine._();

  static final instance = OnDeviceSeparationEngine._();
  Future<_Worker>? _worker;
  Future<void> _queue = Future<void>.value();

  Future<void> prepare(String modelPath) async {
    await _getWorker(modelPath);
  }

  Future<_Worker> _getWorker(String modelPath) async {
    final loading = _worker ??= _Worker.start(modelPath);
    try {
      final worker = await loading;
      if (!worker.isClosed) return worker;
    } catch (_) {
      if (identical(_worker, loading)) _worker = null;
      rethrow;
    }
    if (identical(_worker, loading)) _worker = null;
    return _getWorker(modelPath);
  }

  Future<void> process({
    required String modelPath,
    required String inputPath,
    required String outputPath,
    required SeparationTarget target,
    SeparationProgressCallback? onProgress,
    SeparationCancelToken? cancelToken,
  }) async {
    final previous = _queue;
    final finished = Completer<void>();
    _queue = finished.future;
    try {
      await previous;
      cancelToken?.throwIfCancelled();
      onProgress?.call(
        const SeparationProgress(stage: SeparationStage.warmingUpEngine),
      );
      final worker = await _getWorker(modelPath);
      cancelToken?.throwIfCancelled();
      await worker.process(
        inputPath,
        outputPath,
        target,
        onProgress,
        cancelToken,
      );
    } finally {
      finished.complete();
    }
  }

  Future<void> dispose() async {
    final previous = _queue;
    final finished = Completer<void>();
    _queue = finished.future;
    try {
      await previous;
      final loading = _worker;
      _worker = null;
      if (loading != null) await (await loading).close();
    } finally {
      finished.complete();
    }
  }
}

typedef _Start = ({String modelPath, SendPort events});
typedef _Run = ({
  String input,
  String output,
  SeparationTarget target,
  int runOptions,
});
typedef _Progress = ({int completed, int total});

enum _Command { cancel, close }

Future<void> _workerMain(_Start start) async {
  final timer = Stopwatch()..start();
  OnnxInferenceRunner? runner;
  try {
    runner = OnnxInferenceRunner.load(start.modelPath);
    appLog.d('MDX session loaded in ${timer.elapsedMilliseconds}ms');
    final commands = ReceivePort();
    SeparationCancelToken? token;
    commands.listen((Object? command) async {
      if (command == _Command.cancel) {
        token?.cancel();
        return;
      }
      if (command == _Command.close) {
        commands.close();
        runner!.dispose();
        OrtEnv.instance.release();
        return;
      }
      final job = command! as _Run;
      final cancel = token = SeparationCancelToken();
      try {
        final inputFile = await File(job.input).open();
        try {
          final input = MdxPcmReader(inputFile);
          final frames = await input.frameCount();
          final outputFile = await File(job.output).open(mode: FileMode.write);
          try {
            await MdxSeparator.separate(
              frameCount: frames,
              readFrames: input.read,
              writeFrames: MdxPcmWriter(outputFile).write,
              target: job.target,
              spectrum: runner!.input,
              runSpectrum: () => runner!.runSpectrum(job.runOptions),
              cancelToken: cancel,
              onProgress: (completed, total) =>
                  start.events.send((completed: completed, total: total)),
            );
          } finally {
            await outputFile.close();
          }
        } finally {
          await inputFile.close();
        }
        start.events.send(true);
      } catch (error, stack) {
        start.events.send('$error\n$stack');
      } finally {
        token = null;
      }
    });
    start.events.send(commands.sendPort);
  } catch (_) {
    runner?.dispose();
    OrtEnv.instance.release();
    rethrow;
  }
}

class _Worker {
  _Worker(this._events) {
    _events.listen(_receive);
  }

  static const _chunkTimeout = Duration(seconds: 90);

  final ReceivePort _events;
  final _ready = Completer<SendPort>();
  final _exited = Completer<void>();
  Completer<void>? _job;
  SeparationProgressCallback? _onProgress;
  void Function()? _resetTimeout;
  String? _exitError;

  bool get isClosed => _exited.isCompleted;

  static Future<_Worker> start(String path) async {
    final events = ReceivePort();
    final worker = _Worker(events);
    try {
      await Isolate.spawn<_Start>(
        _workerMain,
        (modelPath: path, events: events.sendPort),
        onError: events.sendPort,
        onExit: events.sendPort,
        debugName: 'SoutNaqi MDX',
      );
      await worker._ready.future;
      return worker;
    } catch (_) {
      events.close();
      rethrow;
    }
  }

  void _receive(Object? message) {
    if (message == null) {
      final error = StateError(_exitError ?? 'MDX worker stopped');
      if (!_ready.isCompleted) _ready.completeError(error);
      final job = _job;
      if (job != null && !job.isCompleted) job.completeError(error);
      _exited.complete();
      _events.close();
    } else if (message is SendPort) {
      _ready.complete(message);
    } else if (message is _Progress) {
      _resetTimeout?.call();
      _onProgress?.call(
        SeparationProgress(
          stage: SeparationStage.separating,
          progress: message.completed / message.total,
          chunkIndex: message.completed,
          totalChunks: message.total,
        ),
      );
    } else if (message is List) {
      // Isolate error port sends an error and stack before its exit message.
      _exitError = message.join('\n');
    } else {
      final job = _job;
      if (job == null || job.isCompleted) return;
      if (message == true) {
        job.complete();
      } else {
        job.completeError(StateError(message.toString()));
      }
    }
  }

  Future<void> process(
    String input,
    String output,
    SeparationTarget target,
    SeparationProgressCallback? onProgress,
    SeparationCancelToken? cancelToken,
  ) async {
    final commands = await _ready.future;
    cancelToken?.throwIfCancelled();
    if (isClosed) throw StateError('MDX worker stopped');
    final options = OrtRunOptions();
    final job = _job = Completer<void>();
    Timer? timer;
    var timedOut = false;

    void stop() {
      commands.send(_Command.cancel);
      try {
        // The run options remain valid until the worker acknowledges the run.
        options.setTerminate();
      } catch (error) {
        appLog.w('Could not interrupt ONNX run', error: error);
      }
    }

    void resetTimeout() {
      timer?.cancel();
      timer = Timer(_chunkTimeout, () {
        timedOut = true;
        stop();
      });
    }

    _resetTimeout = resetTimeout;
    _onProgress = cancelToken == null
        ? onProgress
        : (progress) {
            if (!cancelToken.isCancelled) onProgress?.call(progress);
          };
    cancelToken?.addCancelListener(stop);
    try {
      commands.send((
        input: input,
        output: output,
        target: target,
        runOptions: options.address,
      ));
      resetTimeout();
      try {
        await job.future;
      } catch (_) {
        cancelToken?.throwIfCancelled();
        if (timedOut) throw const AppException(messageKey: 'separationTimeout');
        rethrow;
      }
      cancelToken?.throwIfCancelled();
      if (timedOut) throw const AppException(messageKey: 'separationTimeout');
    } finally {
      timer?.cancel();
      cancelToken?.removeCancelListener(stop);
      _resetTimeout = null;
      _onProgress = null;
      _job = null;
      options.release();
    }
  }

  Future<void> close() async {
    if (isClosed) return;
    (await _ready.future).send(_Command.close);
    await _exited.future;
  }
}
