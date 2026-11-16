import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:soutnaqi/core/errors/app_exception.dart';
import 'package:soutnaqi/core/logging/app_log.dart';
import 'package:soutnaqi/core/services/background_task_service.dart';
import 'package:soutnaqi/features/audio_processing/data/audio_operation.dart';
import 'package:soutnaqi/features/audio_processing/data/audio_processing_service.dart';
import 'package:soutnaqi/features/audio_processing/data/ffmpeg_audio_codec.dart';
import 'package:soutnaqi/features/export/data/local_export_service.dart';
import 'package:soutnaqi/features/history/data/models/project_record.dart';
import 'package:soutnaqi/features/history/data/project_history_repository.dart';
import 'package:soutnaqi/features/media/data/media_picker_repository.dart';
import 'package:soutnaqi/features/media/data/models/media_file.dart';
import 'package:soutnaqi/features/separation/data/separation_cancel_token.dart';
import 'package:soutnaqi/features/separation/data/separation_progress.dart';
import 'package:soutnaqi/features/separation/data/separation_service.dart';
import 'package:soutnaqi/features/separation/data/separation_target.dart';
import 'package:soutnaqi/features/video_processing/data/video_operation.dart';
import 'package:soutnaqi/features/video_processing/data/video_processing_service.dart';
import 'package:soutnaqi/features/video_processing/data/video_to_audio_options.dart';
import 'package:soutnaqi/features/waveform/data/waveform_service.dart';
import 'package:soutnaqi/features/workspace/cubit/workspace_state.dart';

class WorkspaceCubit extends Cubit<WorkspaceState> {
  WorkspaceCubit({
    required MediaPickerRepository mediaPickerRepository,
    required AudioProcessingService audioProcessingService,
    required VideoProcessingService videoProcessingService,
    required WaveformService waveformService,
    required ProjectHistoryRepository projectHistoryRepository,
    required SeparationService separationService,
    required LocalExportService localExportService,
  })  : _mediaPickerRepository = mediaPickerRepository,
        _audioProcessingService = audioProcessingService,
        _videoProcessingService = videoProcessingService,
        _waveformService = waveformService,
        _projectHistoryRepository = projectHistoryRepository,
        _separationService = separationService,
        _localExportService = localExportService,
        super(const WorkspaceState());

  final MediaPickerRepository _mediaPickerRepository;
  final AudioProcessingService _audioProcessingService;
  final VideoProcessingService _videoProcessingService;
  final WaveformService _waveformService;
  final ProjectHistoryRepository _projectHistoryRepository;
  final SeparationService _separationService;
  final LocalExportService _localExportService;
  final AudioPlayer _player = AudioPlayer();

  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  SeparationCancelToken? _separationCancelToken;
  DateTime? _separatingStartedAt;
  int _activeOperationId = 0;
  _SeparatedClip? _separatedClip;

  Future<void> initialize() async {
    _positionSubscription = _player.positionStream.listen((position) {
      emit(state.copyWith(position: position));
    });
    _durationSubscription = _player.durationStream.listen((duration) {
      if (duration == null) return;
      emit(
        state.copyWith(
          duration: duration,
          trimEnd: state.trimEnd > Duration.zero ? state.trimEnd : duration,
        ),
      );
    });
    _playerStateSubscription = _player.playerStateStream.listen((playerState) {
      final isCompleted =
          playerState.processingState == ProcessingState.completed;
      final isReady = playerState.processingState == ProcessingState.ready ||
          playerState.processingState == ProcessingState.completed ||
          playerState.processingState == ProcessingState.buffering;

      emit(
        state.copyWith(
          isPlaying: playerState.playing && !isCompleted,
          isPlayerReady: isReady,
        ),
      );
    });
  }

  Future<bool> pickAudio() => _pickMedia(_mediaPickerRepository.pickAudio);

  Future<bool> pickVideo() => _pickMedia(_mediaPickerRepository.pickVideo);

  Future<void> importMediaFromPath(String path) async {
    emit(
      state.copyWith(
        status: WorkspaceStatus.picking,
        clearProcessed: true,
        clearHistoryPath: true,
        clearLastOperation: true,
        waveformPeaks: const [],
      ),
    );
    try {
      final media = await _mediaPickerRepository.parseLocalFilePath(path);
      await _applyMedia(media);
    } catch (error) {
      emit(
        state.copyWith(
          status: state.hasMedia ? WorkspaceStatus.ready : WorkspaceStatus.empty,
        ),
      );
      throw AppException(messageKey: 'mediaPickFailed', cause: error);
    }
  }

  Future<void> importDroppedFile(XFile file) async {
    emit(
      state.copyWith(
        status: WorkspaceStatus.picking,
        clearProcessed: true,
        clearHistoryPath: true,
        clearLastOperation: true,
        waveformPeaks: const [],
      ),
    );
    try {
      final media = await _mediaPickerRepository.parseDroppedFile(file);
      await _applyMedia(media);
    } on AppException {
      emit(
        state.copyWith(
          status: state.hasMedia ? WorkspaceStatus.ready : WorkspaceStatus.empty,
        ),
      );
      rethrow;
    } catch (error) {
      emit(
        state.copyWith(
          status: state.hasMedia ? WorkspaceStatus.ready : WorkspaceStatus.empty,
        ),
      );
      throw AppException(messageKey: 'mediaPickFailed', cause: error);
    }
  }

  Future<bool> _pickMedia(Future<MediaFile?> Function() picker) async {
    emit(
      state.copyWith(
        status: WorkspaceStatus.picking,
        clearProcessed: true,
        clearHistoryPath: true,
        clearLastOperation: true,
        waveformPeaks: const [],
      ),
    );
    try {
      final media = await picker();
      if (media == null) {
        emit(
          state.copyWith(
            status: state.hasMedia ? WorkspaceStatus.ready : WorkspaceStatus.empty,
          ),
        );
        return false;
      }

      await _applyMedia(media);
      return true;
    } on AppException {
      emit(
        state.copyWith(
          status: state.hasMedia ? WorkspaceStatus.ready : WorkspaceStatus.empty,
        ),
      );
      rethrow;
    } catch (error) {
      emit(
        state.copyWith(
          status: state.hasMedia ? WorkspaceStatus.ready : WorkspaceStatus.empty,
        ),
      );
      throw AppException(messageKey: 'mediaPickFailed', cause: error);
    }
  }

  Future<void> _applyMedia(MediaFile media) async {
    _separatedClip = null;
    await _player.stop();
    emit(
      WorkspaceState(
        status: WorkspaceStatus.ready,
        media: media,
      ),
    );

    if (media.isAudio) {
      await _loadAudioSource(media: media, source: PlaybackSource.original);
      unawaited(_loadWaveform(media));
    }
  }

  Future<void> _loadWaveform(MediaFile media) async {
    emit(state.copyWith(isWaveformLoading: true));
    try {
      final peaks = await _waveformService.extractPeaks(media: media);
      if (isClosed || !_isCurrentWaveform(media)) return;
      final clip = _activeSeparatedClip;
      if (clip != null && identical(state.media, media)) {
        clip.originalPeaks = peaks;
      }
      emit(state.copyWith(
        waveformPeaks: clip != null && state.playbackSource == PlaybackSource.processed
            ? clip.peaks
            : peaks,
        isWaveformLoading: false,
      ));
    } catch (error) {
      appLog.e('❌ Waveform load failed', error: error);
      if (!isClosed && _isCurrentWaveform(media)) {
        emit(state.copyWith(isWaveformLoading: false));
      }
    }
  }

  bool _isCurrentWaveform(MediaFile media) =>
      identical(state.media, media) ||
      (media.path != null && state.processedPath == media.path);

  _SeparatedClip? get _activeSeparatedClip {
    final clip = _separatedClip;
    return clip?.path == state.processedPath ? clip : null;
  }

  Future<void> processAudio(
    AudioOperation operation, {
    double speed = 1.0,
    bool useTrimRange = false,
  }) async {
    final media = state.media;
    if (media == null || !media.isAudio) {
      throw const AppException(messageKey: 'processingAudioOnly');
    }

    _ensureLocalProcessing(media);

    if (_isSeparationOperation(operation)) {
      return _processAudioSeparation(operation, useTrimRange: useTrimRange);
    }

    final operationId = ++_activeOperationId;
    await BackgroundTaskService.instance.acquireWakeLock();

    emit(
      state.copyWith(
        status: WorkspaceStatus.processing,
        activeOperation: operation,
        clearProcessed: true,
        clearHistoryPath: true,
        processingPhase: WorkspaceProcessingPhase.generic,
      ),
    );

    try {
      final outputPath = await _audioProcessingService.process(
        inputPath: media.path!,
        operation: operation,
        trimStart: operation == AudioOperation.trim ? state.trimStart : null,
        trimEnd: operation == AudioOperation.trim ? state.effectiveTrimEnd : null,
        speed: speed,
      );

      if (_activeOperationId != operationId) return;

      emit(
        state.copyWith(
          status: WorkspaceStatus.processed,
          processedPath: outputPath,
          playbackSource: PlaybackSource.processed,
          clearOperation: true,
          clearProcessingOverlay: true,
          lastOperation: _operationKey(operation),
        ),
      );

      await _loadProcessedOutput(outputPath);
      await _loadWaveform(
        MediaFile(
          name: _fileNameFromPath(outputPath),
          kind: MediaKind.audio,
          mimeType: FfmpegAudioCodec.mimeType,
          sizeBytes: 0,
          path: outputPath,
        ),
      );
    } on AppException {
      if (_activeOperationId == operationId) {
        emit(
          state.copyWith(
            status: WorkspaceStatus.ready,
            clearOperation: true,
            clearProcessingOverlay: true,
          ),
        );
      }
      rethrow;
    } catch (error) {
      if (_activeOperationId == operationId) {
        emit(
          state.copyWith(
            status: WorkspaceStatus.ready,
            clearOperation: true,
            clearProcessingOverlay: true,
          ),
        );
      }
      throw AppException(messageKey: 'processingFailed', cause: error);
    } finally {
      await BackgroundTaskService.instance.releaseWakeLock();
    }
  }

  bool get canSeparateAudioRange => _separationService is MediaSeparationService;

  Future<void> _processAudioSeparation(
    AudioOperation operation, {
    required bool useTrimRange,
  }) async {
    final media = state.media!;
    final service = _separationService;
    final target = _separationTargetFromAudioOperation(operation);
    final start = useTrimRange ? state.trimStart : null;
    final end = useTrimRange ? state.effectiveTrimEnd : null;
    final sourceDuration = _activeSeparatedClip?.sourceDuration ?? state.duration;
    if (start != null && end! <= start) {
      throw const AppException(messageKey: 'separationFailed');
    }
    await _runSeparation(
      audioOperation: operation,
      run: (progress, cancelToken) => service is MediaSeparationService
          ? service.separate(
              inputAudioPath: media.path!,
              start: start,
              end: end,
              target: target,
              onProgress: progress,
              cancelToken: cancelToken,
            )
          : service.separate(
              inputAudioPath: media.path!,
              target: target,
              onProgress: progress,
              cancelToken: cancelToken,
            ),
      apply: (path, operationId) => _applySeparatedAudio(
        outputPath: path,
        operationId: operationId,
        operationKey: _operationKey(operation),
        start: start,
        end: end,
        sourceDuration: sourceDuration,
      ),
    );
  }

  Future<void> _processVideoSeparation(VideoOperation operation) async {
    final media = state.media!;
    final service = _separationService;
    final target = _separationTargetFromVideoOperation(operation);
    await _runSeparation(
      videoOperation: operation,
      run: (progress, cancelToken) {
        if (service is MediaSeparationService) {
          return service.separateVideo(
            videoPath: media.path!,
            target: target,
            onProgress: progress,
            cancelToken: cancelToken,
          );
        }
        return _separateVideoViaLegacyService(
          media.path!, target, progress, cancelToken,
        );
      },
      apply: (path, operationId) async {
        await _player.stop();
        if (!_isCurrentOperation(operationId)) return;
        emit(state.copyWith(
          status: WorkspaceStatus.processed,
          processedPath: path,
          playbackSource: PlaybackSource.processed,
          clearVideoOperation: true,
          clearProcessingOverlay: true,
          lastOperation: _videoOperationKey(operation),
        ));
      },
    );
  }

  Future<String> _separateVideoViaLegacyService(
    String path,
    SeparationTarget target,
    SeparationProgressCallback onProgress,
    SeparationCancelToken cancelToken,
  ) async {
    String? audioPath;
    String? separatedPath;
    try {
      cancelToken.throwIfCancelled();
      audioPath = await _videoProcessingService.process(
        inputPath: path,
        operation: VideoOperation.extractAudio,
      );
      cancelToken.throwIfCancelled();
      separatedPath = await _separationService.separate(
        inputAudioPath: audioPath,
        target: target,
        onProgress: onProgress,
        cancelToken: cancelToken,
      );
      cancelToken.throwIfCancelled();
      onProgress(const SeparationProgress(stage: SeparationStage.finalizingVideo));
      return await _videoProcessingService.replaceAudioTrack(
        videoPath: path,
        audioPath: separatedPath,
      );
    } finally {
      if (audioPath != null) await _deleteSeparationOutput(audioPath);
      if (separatedPath != null) await _deleteSeparationOutput(separatedPath);
    }
  }

  Future<void> _runSeparation({
    AudioOperation? audioOperation,
    VideoOperation? videoOperation,
    required Future<String> Function(
      SeparationProgressCallback, SeparationCancelToken,
    ) run,
    required Future<void> Function(String, int) apply,
  }) async {
    _ensureSeparationSupported();
    if (state.isBusy) return;
    final operationId = ++_activeOperationId;
    final cancelToken = SeparationCancelToken();
    _separationCancelToken = cancelToken;
    _separatingStartedAt = null;
    emit(state.copyWith(
      status: WorkspaceStatus.processing,
      activeOperation: audioOperation,
      activeVideoOperation: videoOperation,
      processingPhase: videoOperation == null
          ? WorkspaceProcessingPhase.preparingAudio
          : WorkspaceProcessingPhase.extractingAudio,
      updateProcessingProgress: true,
      clearProcessingChunks: true,
    ));
    await BackgroundTaskService.instance.acquireWakeLock();

    String? outputPath;
    try {
      cancelToken.throwIfCancelled();
      outputPath = await run((progress) {
        if (_isCurrentOperation(operationId) && !cancelToken.isCancelled) {
          _reportSeparationProgress(progress);
        }
      }, cancelToken);
      cancelToken.throwIfCancelled();
      if (_isCurrentOperation(operationId)) await apply(outputPath, operationId);
    } catch (error) {
      if (_isCurrentOperation(operationId)) {
        emit(state.copyWith(
          status: WorkspaceStatus.ready,
          clearOperation: true,
          clearVideoOperation: true,
          clearProcessingOverlay: true,
        ));
      }
      if (error is AppException) rethrow;
      throw AppException(messageKey: 'separationFailed', cause: error);
    } finally {
      if (outputPath != null && state.processedPath != outputPath) {
        await _deleteSeparationOutput(outputPath);
      }
      await BackgroundTaskService.instance.releaseWakeLock();
      if (identical(_separationCancelToken, cancelToken)) {
        _separationCancelToken = null;
      }
    }
  }

  bool _isCurrentOperation(int id) => !isClosed && _activeOperationId == id;

  Future<void> _deleteSeparationOutput(String path) async {
    try {
      await File(path).delete();
    } on FileSystemException catch (error) {
      appLog.w('Could not delete separation temporary file', error: error);
    }
  }

  /// Cancels in-flight separation or processing immediately.
  void cancelProcessing() {
    if (!state.hasProcessingOverlay) return;
    appLog.d('⚡ Cancelling active processing immediately');
    _activeOperationId++;
    final token = _separationCancelToken;
    token?.cancel();
    if (token == null || _separationService is! MediaSeparationService) {
      unawaited(FFmpegKit.cancel());
    }
    emit(
      state.copyWith(
        status: WorkspaceStatus.ready,
        clearOperation: true,
        clearVideoOperation: true,
        clearProcessingOverlay: true,
        updateProcessingProgress: true,
        processingProgress: 0,
      ),
    );
  }

  /// Backward-compatible alias for cancelProcessing.
  void cancelSeparation() => cancelProcessing();

  void _reportSeparationProgress(SeparationProgress progress) {
    if (isClosed || (_separationCancelToken?.isCancelled ?? false)) return;

    final phase = switch (progress.stage) {
      SeparationStage.preparingAudio => WorkspaceProcessingPhase.preparingAudio,
      SeparationStage.loadingModel => WorkspaceProcessingPhase.loadingModel,
      SeparationStage.warmingUpEngine => WorkspaceProcessingPhase.warmingUpEngine,
      SeparationStage.separating => WorkspaceProcessingPhase.separating,
      SeparationStage.encodingOutput => WorkspaceProcessingPhase.encodingOutput,
      SeparationStage.finalizingVideo => WorkspaceProcessingPhase.finalizingVideo,
    };

    final isSeparating = phase == WorkspaceProcessingPhase.separating;
    if (!isSeparating) {
      _separatingStartedAt = null;
    } else {
      _separatingStartedAt ??= DateTime.now();
    }

    emit(
      state.copyWith(
        processingPhase: phase,
        updateProcessingProgress: true,
        processingProgress: progress.progress,
        clearProcessingChunks: !isSeparating,
        processingChunkCurrent: progress.chunkIndex,
        processingChunkTotal: progress.totalChunks,
        updateProcessingEta: isSeparating,
        processingEta: isSeparating
            ? _estimateRemaining(
                current: progress.chunkIndex,
                total: progress.totalChunks,
              )
            : null,
      ),
    );
  }

  Duration? _estimateRemaining({required int? current, required int? total}) {
    final startedAt = _separatingStartedAt;
    if (startedAt == null || current == null || total == null) return null;
    if (current <= 0 || total <= current) return null;
    final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
    if (elapsedMs < 400) return null;
    final remainingMs = (elapsedMs / current * (total - current)).round();
    if (remainingMs <= 0) return null;
    return Duration(milliseconds: remainingMs);
  }

  Future<void> _applySeparatedAudio({
    required String outputPath,
    required int operationId,
    required String operationKey,
    required Duration sourceDuration,
    Duration? start,
    Duration? end,
  }) async {
    await _player.stop();
    if (!_isCurrentOperation(operationId)) return;
    final originalPeaks = _activeSeparatedClip?.originalPeaks ?? state.waveformPeaks;
    final clip = _separatedClip = start != null && end != null
        ? _SeparatedClip(outputPath, start, end, sourceDuration, originalPeaks)
        : null;
    emit(
      state.copyWith(
        status: WorkspaceStatus.processed,
        processedPath: outputPath,
        playbackSource: PlaybackSource.processed,
        lastOperation: operationKey,
        clearOperation: true,
        clearProcessingOverlay: true,
        clearHistoryPath: true,
        position: Duration.zero,
        duration: clip?.duration ?? sourceDuration,
        trimStart: Duration.zero,
        trimEnd: Duration.zero,
        waveformPeaks: clip?.peaks ?? originalPeaks,
      ),
    );
    await _loadProcessedOutput(outputPath);
  }

  void _ensureSeparationSupported() {
    if (!_separationService.isSupported) {
      throw const AppException(messageKey: 'separationNotConfigured');
    }
  }

  bool _isSeparationOperation(AudioOperation operation) {
    return operation == AudioOperation.isolateVocals ||
        operation == AudioOperation.isolateMusic;
  }

  bool _isVideoSeparationOperation(VideoOperation operation) {
    return operation == VideoOperation.isolateVocals ||
        operation == VideoOperation.isolateMusic;
  }

  SeparationTarget _separationTargetFromAudioOperation(
    AudioOperation operation,
  ) {
    return switch (operation) {
      AudioOperation.isolateVocals => SeparationTarget.vocals,
      AudioOperation.isolateMusic => SeparationTarget.instrumental,
      _ => throw StateError('Not a separation operation: $operation'),
    };
  }

  SeparationTarget _separationTargetFromVideoOperation(
    VideoOperation operation,
  ) {
    return switch (operation) {
      VideoOperation.isolateVocals => SeparationTarget.vocals,
      VideoOperation.isolateMusic => SeparationTarget.instrumental,
      _ => throw StateError('Not a separation operation: $operation'),
    };
  }

  Future<void> applyTrim() async {
    if (!state.isTrimModified) return;
    await processAudio(AudioOperation.trim);
  }

  Future<void> processVideo(VideoOperation operation, {double speed = 1.0}) async {
    final media = state.media;
    if (media == null || !media.isVideo) {
      throw const AppException(messageKey: 'processingVideoOnly');
    }

    _ensureLocalProcessing(media);

    if (_isVideoSeparationOperation(operation)) {
      return _processVideoSeparation(operation);
    }

    final operationId = ++_activeOperationId;
    await BackgroundTaskService.instance.acquireWakeLock();

    emit(
      state.copyWith(
        status: WorkspaceStatus.processing,
        activeVideoOperation: operation,
        clearProcessed: true,
        clearHistoryPath: true,
        processingPhase: WorkspaceProcessingPhase.generic,
      ),
    );

    try {
      final outputPath = await _videoProcessingService.process(
        inputPath: media.path!,
        operation: operation,
        speed: speed,
      );

      if (_activeOperationId != operationId) return;

      if (operation == VideoOperation.extractAudio) {
        final audioFile = MediaFile(
          name: _fileNameFromPath(outputPath),
          kind: MediaKind.audio,
          mimeType: FfmpegAudioCodec.mimeType,
          sizeBytes: 0,
          path: outputPath,
        );
        await _player.stop();
        emit(
          WorkspaceState(
            status: WorkspaceStatus.processed,
            media: audioFile,
            processedPath: outputPath,
            playbackSource: PlaybackSource.processed,
            lastOperation: 'extract_audio',
          ),
        );
        await _loadProcessedOutput(outputPath);
        unawaited(_loadWaveform(audioFile));
        return;
      }

      emit(
        state.copyWith(
          status: WorkspaceStatus.processed,
          processedPath: outputPath,
          playbackSource: PlaybackSource.processed,
          clearVideoOperation: true,
          clearProcessingOverlay: true,
          lastOperation: _videoOperationKey(operation),
        ),
      );
    } on AppException {
      if (_activeOperationId == operationId) {
        emit(
          state.copyWith(
            status: WorkspaceStatus.ready,
            clearVideoOperation: true,
            clearProcessingOverlay: true,
          ),
        );
      }
      rethrow;
    } catch (error) {
      if (_activeOperationId == operationId) {
        emit(
          state.copyWith(
            status: WorkspaceStatus.ready,
            clearVideoOperation: true,
            clearProcessingOverlay: true,
          ),
        );
      }
      throw AppException(messageKey: 'processingFailed', cause: error);
    } finally {
      await BackgroundTaskService.instance.releaseWakeLock();
    }
  }

  Future<String> convertVideoToAudio(
    VideoToAudioOptions options, {
    VideoToAudioDestination destination = VideoToAudioDestination.workspace,
  }) async {
    final media = state.media;
    if (media == null || !media.isVideo || media.path == null) {
      throw const AppException(messageKey: 'mediaPickFailed');
    }

    final operationId = ++_activeOperationId;

    await BackgroundTaskService.instance.acquireWakeLock();
    emit(
      state.copyWith(
        status: WorkspaceStatus.processing,
        activeVideoOperation: VideoOperation.extractAudio,
        clearProcessed: true,
        clearHistoryPath: true,
        processingPhase: WorkspaceProcessingPhase.extractingAudio,
      ),
    );

    try {
      final outputPath = await _videoProcessingService.convertVideoToAudio(
        inputPath: media.path!,
        options: options,
      );

      if (_activeOperationId != operationId) return outputPath;

      final baseName = p.basenameWithoutExtension(media.name);
      final fileName = '${baseName}_audio.${options.format.extension}';

      if (destination == VideoToAudioDestination.saveToDevice) {
        final exportResult = await _localExportService.saveToDevice(
          sourcePath: outputPath,
          bytes: null,
          fileName: fileName,
          isVideo: false,
        );
        await _projectHistoryRepository.saveProject(
          localPath: outputPath,
          fileName: fileName,
          mediaType: ProjectMediaType.audio,
          operation: 'extract_audio',
        );
        emit(
          state.copyWith(
            status: WorkspaceStatus.processed,
            processedPath: outputPath,
            clearProcessingOverlay: true,
            clearVideoOperation: true,
            lastOperation: 'extract_audio',
          ),
        );
        return exportResult.displayPath ?? outputPath;
      }

      if (destination == VideoToAudioDestination.share) {
        await SharePlus.instance.share(
          ShareParams(files: [XFile(outputPath)]),
        );
        await _projectHistoryRepository.saveProject(
          localPath: outputPath,
          fileName: fileName,
          mediaType: ProjectMediaType.audio,
          operation: 'extract_audio',
        );
        emit(
          state.copyWith(
            status: WorkspaceStatus.processed,
            processedPath: outputPath,
            clearProcessingOverlay: true,
            clearVideoOperation: true,
            lastOperation: 'extract_audio',
          ),
        );
        return outputPath;
      }

      // Default: Open in Workspace
      final file = File(outputPath);
      final sizeBytes = file.existsSync() ? file.lengthSync() : 0;
      final audioFile = MediaFile(
        name: _fileNameFromPath(outputPath),
        kind: MediaKind.audio,
        mimeType: options.format.mimeType,
        sizeBytes: sizeBytes,
        path: outputPath,
      );

      await _player.stop();
      emit(
        WorkspaceState(
          status: WorkspaceStatus.ready,
          media: audioFile,
          lastOperation: 'extract_audio',
        ),
      );
      await _loadAudioSource(media: audioFile, source: PlaybackSource.original);
      unawaited(_loadWaveform(audioFile));
      unawaited(
        _projectHistoryRepository.saveProject(
          localPath: outputPath,
          fileName: audioFile.name,
          mediaType: ProjectMediaType.audio,
          operation: 'extract_audio',
        ),
      );
      return outputPath;
    } on AppException {
      if (_activeOperationId == operationId) {
        emit(
          state.copyWith(
            status: WorkspaceStatus.ready,
            clearVideoOperation: true,
            clearProcessingOverlay: true,
          ),
        );
      }
      rethrow;
    } catch (error) {
      if (_activeOperationId == operationId) {
        emit(
          state.copyWith(
            status: WorkspaceStatus.ready,
            clearVideoOperation: true,
            clearProcessingOverlay: true,
          ),
        );
      }
      throw AppException(messageKey: 'processingFailed', cause: error);
    } finally {
      await BackgroundTaskService.instance.releaseWakeLock();
    }
  }

  void updateTrimStart(Duration value) {
    final max = state.effectiveTrimEnd;
    final next = value > max ? max : value;
    emit(state.copyWith(trimStart: next < Duration.zero ? Duration.zero : next));
  }

  void updateTrimEnd(Duration value) {
    final min = state.trimStart;
    final max = state.duration;
    var next = value;
    if (next < min) next = min;
    if (max > Duration.zero && next > max) next = max;
    emit(state.copyWith(trimEnd: next));
  }

  Future<LocalExportResult> saveExport() async {
    emit(state.copyWith(isSaving: true));
    try {
      final exportPath = _resolveExportPath();
      final media = state.media;
      if (exportPath == null && (media == null || !media.hasLocalPath)) {
        if (!kIsWeb || media?.bytes == null) {
          throw const AppException(messageKey: 'exportFailed');
        }
      }

      final fileName = exportPath != null
          ? _fileNameFromPath(exportPath)
          : media!.name;

      final isVideo = media?.isVideo ?? false;

      final result = await _localExportService.saveToDevice(
        sourcePath: exportPath ?? media?.path,
        bytes: kIsWeb && exportPath == null ? media?.bytes : null,
        fileName: fileName,
        isVideo: isVideo,
      );
      emit(state.copyWith(isSaving: false));
      return result;
    } on AppException {
      emit(state.copyWith(isSaving: false));
      rethrow;
    } catch (error) {
      emit(state.copyWith(isSaving: false));
      throw AppException(messageKey: 'saveFailed', cause: error);
    }
  }

  Future<void> shareExport() async {
    emit(state.copyWith(isSharing: true));
    try {
      final exportPath = _resolveExportPath();
      if (exportPath != null) {
        await SharePlus.instance.share(
          ShareParams(files: [XFile(exportPath)]),
        );
        emit(state.copyWith(isSharing: false));
        return;
      }

      final media = state.media;
      if (kIsWeb && media?.bytes != null) {
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile.fromData(
                Uint8List.fromList(media!.bytes!),
                name: media.name,
                mimeType: media.mimeType,
              ),
            ],
          ),
        );
        emit(state.copyWith(isSharing: false));
        return;
      }

      throw const AppException(messageKey: 'exportFailed');
    } on AppException {
      emit(state.copyWith(isSharing: false));
      rethrow;
    } catch (error) {
      emit(state.copyWith(isSharing: false));
      throw AppException(messageKey: 'exportFailed', cause: error);
    }
  }

  Future<ProjectRecord> saveToHistory() async {
    final exportPath = _resolveExportPath();
    if (exportPath == null) {
      throw const AppException(messageKey: 'exportFailed');
    }

    final media = state.media;
    if (media == null) {
      throw const AppException(messageKey: 'exportFailed');
    }

    emit(state.copyWith(isSavingToHistory: true));
    try {
      final fileName = _fileNameFromPath(exportPath);
      final record = await _projectHistoryRepository.saveProject(
        localPath: exportPath,
        fileName: fileName,
        mediaType: media.isVideo
            ? ProjectMediaType.video
            : ProjectMediaType.audio,
        operation: state.lastOperation,
      );
      emit(
        state.copyWith(
          isSavingToHistory: false,
          historyPath: record.filePath,
        ),
      );
      return record;
    } on AppException {
      emit(state.copyWith(isSavingToHistory: false));
      rethrow;
    } catch (error) {
      emit(state.copyWith(isSavingToHistory: false));
      throw AppException(messageKey: 'saveToHistoryFailed', cause: error);
    }
  }

  Future<void> switchPlaybackSource(PlaybackSource source) async {
    if (source == PlaybackSource.processed && !state.hasProcessedOutput) {
      return;
    }

    final media = state.media;
    if (media == null) return;

    if (state.playbackSource == source) return;
    final wasPlaying = _player.playing;
    final currentPosition = _player.position;

    final clip = _activeSeparatedClip;
    var seekTo = currentPosition;
    if (clip == null) {
      emit(state.copyWith(playbackSource: source));
    } else {
      final original = source == PlaybackSource.original;
      final duration = original ? clip.sourceDuration : clip.duration;
      seekTo = original ? currentPosition + clip.start : currentPosition - clip.start;
      if (seekTo < Duration.zero) seekTo = Duration.zero;
      if (seekTo > duration) seekTo = duration;
      emit(state.copyWith(
        playbackSource: source,
        duration: duration,
        position: seekTo,
        trimStart: Duration.zero,
        trimEnd: Duration.zero,
        waveformPeaks: original ? clip.originalPeaks : clip.peaks,
      ));
    }

    if (!media.isAudio) return;

    if (source == PlaybackSource.original) {
      await _loadAudioSource(media: media, source: PlaybackSource.original);
    } else {
      await _loadProcessedOutput(state.processedPath!);
    }

    if (seekTo > Duration.zero) {
      await _player.seek(seekTo);
    }
    if (wasPlaying) {
      await _player.play();
    }
  }

  Future<bool> replaceVideoAudioWithPicker() async {
    final media = state.media;
    if (media == null || !media.isVideo) {
      throw const AppException(messageKey: 'processingVideoOnly');
    }

    final pickedAudio = await _mediaPickerRepository.pickAudio();
    if (pickedAudio == null || pickedAudio.path == null) {
      return false;
    }

    _ensureLocalProcessing(media);

    final operationId = ++_activeOperationId;
    await BackgroundTaskService.instance.acquireWakeLock();

    emit(
      state.copyWith(
        status: WorkspaceStatus.processing,
        activeVideoOperation: VideoOperation.replaceAudio,
        clearProcessed: true,
        clearHistoryPath: true,
        processingPhase: WorkspaceProcessingPhase.finalizingVideo,
      ),
    );

    try {
      final outputPath = await _videoProcessingService.replaceAudioTrack(
        videoPath: media.path!,
        audioPath: pickedAudio.path!,
      );

      if (_activeOperationId != operationId) return false;

      await _player.stop();
      emit(
        state.copyWith(
          status: WorkspaceStatus.processed,
          processedPath: outputPath,
          playbackSource: PlaybackSource.processed,
          clearVideoOperation: true,
          clearProcessingOverlay: true,
          lastOperation: 'replace_audio',
        ),
      );
      return true;
    } on AppException {
      if (_activeOperationId == operationId) {
        emit(
          state.copyWith(
            status: WorkspaceStatus.ready,
            clearVideoOperation: true,
            clearProcessingOverlay: true,
          ),
        );
      }
      rethrow;
    } catch (error) {
      if (_activeOperationId == operationId) {
        emit(
          state.copyWith(
            status: WorkspaceStatus.ready,
            clearVideoOperation: true,
            clearProcessingOverlay: true,
          ),
        );
      }
      throw AppException(messageKey: 'processingFailed', cause: error);
    } finally {
      await BackgroundTaskService.instance.releaseWakeLock();
    }
  }

  Future<void> togglePlayback() async {
    if (state.media?.isAudio != true) return;

    final isCompleted =
        _player.processingState == ProcessingState.completed ||
        (state.duration > Duration.zero && state.position >= state.duration);

    if (isCompleted) {
      final start =
          state.trimStart > Duration.zero ? state.trimStart : Duration.zero;
      await _player.seek(start);
      await _player.play();
      return;
    }

    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> seekTo(Duration position) async {
    if (state.media?.isAudio != true) return;
    var target = position;
    if (target < Duration.zero) target = Duration.zero;
    if (state.duration > Duration.zero && target > state.duration) {
      target = state.duration;
    }
    await _player.seek(target);
    emit(state.copyWith(position: target));
  }

  Future<void> seekRelative(Duration offset) async {
    if (state.media?.isAudio != true) return;
    await seekTo(state.position + offset);
  }

  Future<void> seekToFraction(double fraction) async {
    if (state.duration <= Duration.zero) return;
    final clamped = fraction.clamp(0.0, 1.0);
    final target = Duration(
      milliseconds: (state.duration.inMilliseconds * clamped).round(),
    );
    await seekTo(target);
  }

  Future<void> setPlaybackSpeed(double speed) async {
    emit(state.copyWith(playbackSpeed: speed));
    try {
      await _player.setSpeed(speed);
    } catch (error) {
      appLog.w('⚠️ Failed to set playback speed: $error');
    }
  }

  Future<void> clearWorkspace() async {
    appLog.d('🔍 Clearing workspace…');
    _separatedClip = null;
    await _player.stop();
    emit(const WorkspaceState());
  }

  void _ensureLocalProcessing(MediaFile media) {
    if (!_audioProcessingService.isProcessingSupported && media.isAudio) {
      throw const AppException(messageKey: 'processingWebUnsupported');
    }
    if (!_videoProcessingService.isProcessingSupported && media.isVideo) {
      throw const AppException(messageKey: 'processingWebUnsupported');
    }
    if (!media.hasLocalPath) {
      throw const AppException(messageKey: 'processingWebUnsupported');
    }
  }

  String? _resolveExportPath() {
    if (state.hasProcessedOutput) {
      return state.processedPath;
    }
    return state.media?.path;
  }

  String _fileNameFromPath(String path) {
    final separator = path.contains('/') ? '/' : '\\';
    return path.split(separator).last;
  }

  String _operationKey(AudioOperation operation) {
    return switch (operation) {
      AudioOperation.normalize => 'normalize',
      AudioOperation.noiseReduction => 'noise_reduction',
      AudioOperation.trim => 'trim',
      AudioOperation.isolateVocals => 'isolate_vocals',
      AudioOperation.isolateMusic => 'isolate_music',
      AudioOperation.changeSpeed => 'change_speed',
    };
  }

  String _videoOperationKey(VideoOperation operation) {
    return switch (operation) {
      VideoOperation.extractAudio => 'extract_audio',
      VideoOperation.compress => 'compress',
      VideoOperation.isolateVocals => 'isolate_vocals',
      VideoOperation.isolateMusic => 'isolate_music',
      VideoOperation.changeSpeed => 'change_speed',
      VideoOperation.muteVideo => 'mute_video',
      VideoOperation.replaceAudio => 'replace_audio',
    };
  }

  Future<void> _loadProcessedOutput(String path) async {
    try {
      await _player.setFilePath(path);
      await _player.setSpeed(state.playbackSpeed);
      emit(state.copyWith(isPlayerReady: true));
    } catch (error) {
      appLog.e('❌ Player failed to load processed output', error: error);
      emit(state.copyWith(isPlayerReady: false));
    }
  }

  Future<void> _loadAudioSource({
    required MediaFile media,
    required PlaybackSource source,
  }) async {
    if (source == PlaybackSource.processed && state.processedPath != null) {
      await _loadProcessedOutput(state.processedPath!);
      return;
    }

    if (media.hasLocalPath) {
      await _player.setFilePath(media.path!);
      await _player.setSpeed(state.playbackSpeed);
      emit(state.copyWith(isPlayerReady: true));
      return;
    }

    if (kIsWeb && media.bytes != null) {
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.dataFromBytes(
            media.bytes!,
            mimeType: media.mimeType,
          ),
        ),
      );
      emit(state.copyWith(isPlayerReady: true));
      return;
    }

    throw const AppException(messageKey: 'mediaPickFailed');
  }

  @override
  Future<void> close() async {
    _activeOperationId++;
    _separationCancelToken?.cancel();
    await _positionSubscription?.cancel();
    await _durationSubscription?.cancel();
    await _playerStateSubscription?.cancel();
    await _player.dispose();
    return super.close();
  }
}

class _SeparatedClip {
  _SeparatedClip(this.path, this.start, this.end, this.sourceDuration, this.originalPeaks);

  final String path;
  final Duration start;
  final Duration end;
  final Duration sourceDuration;
  List<double> originalPeaks;

  Duration get duration => end - start;

  List<double> get peaks {
    if (originalPeaks.isEmpty || sourceDuration <= Duration.zero) return const [];
    final count = originalPeaks.length;
    final total = sourceDuration.inMicroseconds;
    final first = (start.inMicroseconds * count ~/ total).clamp(0, count - 1);
    final last = ((end.inMicroseconds * count + total - 1) ~/ total).clamp(first + 1, count);
    return originalPeaks.sublist(first, last);
  }
}
