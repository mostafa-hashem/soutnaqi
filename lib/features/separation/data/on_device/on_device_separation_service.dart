import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:soutnaqi/core/config/app_env.dart';
import 'package:soutnaqi/core/errors/app_exception.dart';
import 'package:soutnaqi/core/logging/app_log.dart';
import 'package:soutnaqi/core/services/temp_storage_service.dart';
import 'package:soutnaqi/features/separation/data/on_device/mdx_media_io.dart';
import 'package:soutnaqi/features/separation/data/on_device/on_device_model_repository.dart';
import 'package:soutnaqi/features/separation/data/on_device/on_device_separation_engine.dart';
import 'package:soutnaqi/features/separation/data/separation_cancel_token.dart';
import 'package:soutnaqi/features/separation/data/separation_progress.dart';
import 'package:soutnaqi/features/separation/data/separation_service.dart';
import 'package:soutnaqi/features/separation/data/separation_target.dart';
import 'package:uuid/uuid.dart';

SeparationService createOnDeviceSeparationService() =>
    OnDeviceSeparationService();

Future<void> warmUpOnDeviceSeparationIfReady() async {
  if (!AppEnv.isOnDeviceSeparationSupported) return;
  try {
    final repository = OnDeviceModelRepository();
    if (await repository.isModelCached()) {
      await OnDeviceSeparationEngine.instance.prepare(
        await repository.modelPath(),
      );
    }
  } catch (error) {
    appLog.w('Could not preload the separation model', error: error);
  }
}

Future<void> disposeOnDeviceSeparation() =>
    OnDeviceSeparationEngine.instance.dispose();

typedef _Source = ({
  String path,
  int size,
  DateTime modified,
  DateTime changed,
  bool video,
  Duration? start,
  Duration? end,
});

typedef _ExecuteMedia =
    Future<void> Function(
      List<String> arguments, {
      SeparationCancelToken? cancelToken,
      bool checkVideoAudio,
    });

class OnDeviceSeparationService implements MediaSeparationService {
  OnDeviceSeparationService({
    OnDeviceModelRepository? modelRepository,
    Future<Directory> Function() temporaryDirectory = getTemporaryDirectory,
    _ExecuteMedia executeMedia = MdxMediaIo.execute,
  }) : _modelRepository = modelRepository ?? OnDeviceModelRepository(),
       _temporaryDirectory = temporaryDirectory,
       _executeMedia = executeMedia;

  final OnDeviceModelRepository _modelRepository;
  final Future<Directory> Function() _temporaryDirectory;
  final _ExecuteMedia _executeMedia;
  Future<void> _queue = Future<void>.value();
  ({_Source source, Directory directory})? _cached;

  @override
  bool get isSupported => AppEnv.isOnDeviceSeparationSupported;

  @override
  Future<String> separate({
    required String inputAudioPath,
    required SeparationTarget target,
    SeparationProgressCallback? onProgress,
    SeparationCancelToken? cancelToken,
    Duration? start,
    Duration? end,
  }) => _separate(
    source: inputAudioPath,
    target: target,
    onProgress: onProgress,
    cancelToken: cancelToken,
    start: start,
    end: end,
  );

  @override
  Future<String> separateVideo({
    required String videoPath,
    required SeparationTarget target,
    SeparationProgressCallback? onProgress,
    SeparationCancelToken? cancelToken,
  }) => _separate(
    source: videoPath,
    video: true,
    target: target,
    onProgress: onProgress,
    cancelToken: cancelToken,
  );

  Future<String> _separate({
    required String source,
    required SeparationTarget target,
    SeparationProgressCallback? onProgress,
    SeparationCancelToken? cancelToken,
    bool video = false,
    Duration? start,
    Duration? end,
  }) async {
    if (!isSupported) {
      throw const AppException(messageKey: 'separationNotConfigured');
    }
    final previous = _queue;
    final finished = Completer<void>();
    _queue = finished.future;
    final storage = TempStorageService.instance;
    final total = Stopwatch()..start();
    final decode = Stopwatch();
    Directory? job;
    try {
      await previous;
      cancelToken?.throwIfCancelled();
      onProgress?.call(
        const SeparationProgress(stage: SeparationStage.loadingModel),
      );
      if (!await _modelRepository.isModelCached()) {
        throw const AppException(messageKey: 'separationModelRequired');
      }
      cancelToken?.throwIfCancelled();

      final stat = await File(source).stat();
      if (stat.type != FileSystemEntityType.file) {
        throw const AppException(messageKey: 'mediaPickFailed');
      }
      final key = (
        path: source,
        size: stat.size,
        modified: stat.modified,
        changed: stat.changed,
        video: video,
        start: start,
        end: end,
      );
      final temp = await _temporaryDirectory();
      final cached = _cached;
      if (cached != null &&
          cached.source == key &&
          await cached.directory.exists()) {
        job = cached.directory;
        storage.protect(job);
        final mix = File(p.join(job.path, 'input.pcm'));
        final vocals = File(p.join(job.path, 'vocals.pcm'));
        if (!await mix.exists() || !await vocals.exists()) {
          storage.unprotect(job);
          job = null;
        }
      }
      final cacheHit = job != null;
      if (job == null) {
        _cached = null;
        await _cleanup(cached?.directory, recursive: true);
        job = await temp.createTemp(
          TempStorageService.separationDirectoryPrefix,
        );
        storage.protect(job);
      }
      final input = p.join(job.path, 'input.pcm');
      final vocals = p.join(job.path, 'vocals.pcm');
      final extension = video ? 'mp4' : 'm4a';
      final staging = File(p.join(job.path, 'export.$extension'));

      if (!cacheHit) {
        onProgress?.call(
          const SeparationProgress(stage: SeparationStage.preparingAudio),
        );
        decode.start();
        await _executeMedia(
          MdxMediaIo.decodeArguments(
            source: source,
            pcm: input,
            video: video,
            start: start,
            end: end,
          ),
          cancelToken: cancelToken,
          checkVideoAudio: video,
        );
        decode.stop();
        await OnDeviceSeparationEngine.instance.process(
          modelPath: await _modelRepository.modelPath(),
          inputPath: input,
          outputPath: vocals,
          target: SeparationTarget.vocals,
          onProgress: onProgress,
          cancelToken: cancelToken,
        );
        _cached = (source: key, directory: job);
      }

      onProgress?.call(
        SeparationProgress(
          stage: video
              ? SeparationStage.finalizingVideo
              : SeparationStage.encodingOutput,
        ),
      );
      final encode = Stopwatch()..start();
      try {
        await _executeMedia(
          MdxMediaIo.encodeArguments(
            vocals: vocals,
            destination: staging.path,
            video: video ? source : null,
            mix: target == SeparationTarget.instrumental ? input : null,
          ),
          cancelToken: cancelToken,
        );
        cancelToken?.throwIfCancelled();
        final result = await staging.rename(
          p.join(temp.path, 'soutnaqi_${const Uuid().v4()}.$extension'),
        );
        appLog.d(
          'MDX cached=$cacheHit, decode=${decode.elapsedMilliseconds}ms, '
          'output=${encode.elapsedMilliseconds}ms, total=${total.elapsedMilliseconds}ms',
        );
        return result.path;
      } finally {
        await _cleanup(staging);
      }
    } on AppException {
      rethrow;
    } catch (error, stack) {
      cancelToken?.throwIfCancelled();
      appLog.e('On-device separation failed', error: error, stackTrace: stack);
      throw AppException(messageKey: 'separationFailed', cause: error);
    } finally {
      if (job != null) {
        if (!identical(_cached?.directory, job)) {
          await _cleanup(job, recursive: true);
        }
        storage.unprotect(job);
      }
      finished.complete();
    }
  }

  Future<void> _cleanup(
    FileSystemEntity? file, {
    bool recursive = false,
  }) async {
    if (file == null) return;
    try {
      if (await file.exists()) await file.delete(recursive: recursive);
    } catch (error) {
      appLog.w('Could not clean separation temporary files', error: error);
    }
  }
}
