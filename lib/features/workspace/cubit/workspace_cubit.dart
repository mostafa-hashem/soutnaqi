import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';

import 'package:soutnaqi/core/errors/app_exception.dart';
import 'package:soutnaqi/core/logging/app_log.dart';
import 'package:soutnaqi/features/audio_processing/data/audio_operation.dart';
import 'package:soutnaqi/features/audio_processing/data/audio_processing_service.dart';
import 'package:soutnaqi/features/audio_processing/data/ffmpeg_audio_codec.dart';
import 'package:soutnaqi/features/export/data/local_export_service.dart';
import 'package:soutnaqi/features/history/data/models/project_record.dart';
import 'package:soutnaqi/features/history/data/project_history_repository.dart';
import 'package:soutnaqi/features/media/data/media_picker_repository.dart';
import 'package:soutnaqi/features/media/data/models/media_file.dart';
import 'package:soutnaqi/features/separation/data/separation_service.dart';
import 'package:soutnaqi/features/separation/data/separation_target.dart';
import 'package:soutnaqi/features/video_processing/data/video_operation.dart';
import 'package:soutnaqi/features/video_processing/data/video_processing_service.dart';
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
      emit(
        state.copyWith(
          isPlaying: playerState.playing,
          isPlayerReady: playerState.processingState == ProcessingState.ready,
        ),
      );
    });
  }

  Future<void> pickAudio() => _pickMedia(_mediaPickerRepository.pickAudio);

  Future<void> pickVideo() => _pickMedia(_mediaPickerRepository.pickVideo);

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

  Future<void> _pickMedia(Future<MediaFile?> Function() picker) async {
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
        return;
      }

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

  Future<void> _applyMedia(MediaFile media) async {
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
      emit(state.copyWith(waveformPeaks: peaks, isWaveformLoading: false));
    } catch (error) {
      appLog.e('❌ Waveform load failed', error: error);
      emit(state.copyWith(isWaveformLoading: false));
    }
  }

  Future<void> processAudio(AudioOperation operation) async {
    final media = state.media;
    if (media == null || !media.isAudio) {
      throw const AppException(messageKey: 'processingAudioOnly');
    }

    _ensureLocalProcessing(media);

    if (_isSeparationOperation(operation)) {
      return _processAudioSeparation(operation);
    }

    emit(
      state.copyWith(
        status: WorkspaceStatus.processing,
        activeOperation: operation,
        clearProcessed: true,
        clearHistoryPath: true,
      ),
    );

    try {
      final outputPath = await _audioProcessingService.process(
        inputPath: media.path!,
        operation: operation,
        trimStart: operation == AudioOperation.trim ? state.trimStart : null,
        trimEnd: operation == AudioOperation.trim ? state.effectiveTrimEnd : null,
      );

      emit(
        state.copyWith(
          status: WorkspaceStatus.processed,
          processedPath: outputPath,
          playbackSource: PlaybackSource.processed,
          clearOperation: true,
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
      emit(state.copyWith(status: WorkspaceStatus.ready, clearOperation: true));
      rethrow;
    } catch (error) {
      emit(state.copyWith(status: WorkspaceStatus.ready, clearOperation: true));
      throw AppException(messageKey: 'processingFailed', cause: error);
    }
  }

  Future<void> _processAudioSeparation(AudioOperation operation) async {
    final media = state.media!;
    _ensureSeparationSupported();

    emit(
      state.copyWith(
        status: WorkspaceStatus.processing,
        activeOperation: operation,
        clearProcessed: true,
        clearHistoryPath: true,
      ),
    );

    try {
      final outputPath = await _separationService.separate(
        inputAudioPath: media.path!,
        target: _separationTargetFromAudioOperation(operation),
      );
      await _applySeparatedAudio(
        outputPath: outputPath,
        operationKey: _operationKey(operation),
      );
    } on AppException {
      emit(state.copyWith(status: WorkspaceStatus.ready, clearOperation: true));
      rethrow;
    } catch (error) {
      emit(state.copyWith(status: WorkspaceStatus.ready, clearOperation: true));
      throw AppException(messageKey: 'separationFailed', cause: error);
    }
  }

  Future<void> _processVideoSeparation(VideoOperation operation) async {
    final media = state.media!;
    _ensureSeparationSupported();

    emit(
      state.copyWith(
        status: WorkspaceStatus.processing,
        activeVideoOperation: operation,
        clearProcessed: true,
        clearHistoryPath: true,
      ),
    );

    try {
      final audioPath = await _videoProcessingService.process(
        inputPath: media.path!,
        operation: VideoOperation.extractAudio,
      );
      final separatedAudioPath = await _separationService.separate(
        inputAudioPath: audioPath,
        target: _separationTargetFromVideoOperation(operation),
      );
      final outputPath = await _videoProcessingService.replaceAudioTrack(
        videoPath: media.path!,
        audioPath: separatedAudioPath,
      );
      await _player.stop();
      emit(
        state.copyWith(
          status: WorkspaceStatus.processed,
          processedPath: outputPath,
          playbackSource: PlaybackSource.processed,
          clearVideoOperation: true,
          lastOperation: _videoOperationKey(operation),
        ),
      );
    } on AppException {
      emit(
        state.copyWith(status: WorkspaceStatus.ready, clearVideoOperation: true),
      );
      rethrow;
    } catch (error) {
      emit(
        state.copyWith(status: WorkspaceStatus.ready, clearVideoOperation: true),
      );
      throw AppException(messageKey: 'separationFailed', cause: error);
    }
  }

  Future<void> _applySeparatedAudio({
    required String outputPath,
    required String operationKey,
  }) async {
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
        lastOperation: operationKey,
      ),
    );
    try {
      await _loadProcessedOutput(outputPath);
      unawaited(_loadWaveform(audioFile));
    } catch (error) {
      appLog.e('❌ Failed to prepare separated audio preview', error: error);
    }
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
    await processAudio(AudioOperation.trim);
  }

  Future<void> processVideo(VideoOperation operation) async {
    final media = state.media;
    if (media == null || !media.isVideo) {
      throw const AppException(messageKey: 'processingVideoOnly');
    }

    _ensureLocalProcessing(media);

    if (_isVideoSeparationOperation(operation)) {
      return _processVideoSeparation(operation);
    }

    emit(
      state.copyWith(
        status: WorkspaceStatus.processing,
        activeVideoOperation: operation,
        clearProcessed: true,
        clearHistoryPath: true,
      ),
    );

    try {
      final outputPath = await _videoProcessingService.process(
        inputPath: media.path!,
        operation: operation,
      );

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
          lastOperation: _videoOperationKey(operation),
        ),
      );
    } on AppException {
      emit(
        state.copyWith(status: WorkspaceStatus.ready, clearVideoOperation: true),
      );
      rethrow;
    } catch (error) {
      emit(
        state.copyWith(status: WorkspaceStatus.ready, clearVideoOperation: true),
      );
      throw AppException(messageKey: 'processingFailed', cause: error);
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

  Future<bool> saveExport() async {
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

      final saved = await _localExportService.saveToDevice(
        sourcePath: exportPath ?? media?.path,
        bytes: kIsWeb && exportPath == null ? media?.bytes : null,
        fileName: fileName,
      );
      emit(state.copyWith(isSaving: false));
      return saved;
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

    emit(state.copyWith(playbackSource: source));

    if (!media.isAudio) return;

    if (source == PlaybackSource.original) {
      await _loadAudioSource(media: media, source: PlaybackSource.original);
    } else {
      await _loadProcessedOutput(state.processedPath!);
    }
  }

  Future<void> togglePlayback() async {
    if (state.media?.isAudio != true) return;

    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> seekTo(Duration position) async {
    if (state.media?.isAudio != true) return;
    await _player.seek(position);
  }

  Future<void> seekToFraction(double fraction) async {
    if (state.duration <= Duration.zero) return;
    final clamped = fraction.clamp(0.0, 1.0);
    final target = Duration(
      milliseconds: (state.duration.inMilliseconds * clamped).round(),
    );
    await seekTo(target);
  }

  Future<void> clearWorkspace() async {
    appLog.d('🔍 Clearing workspace…');
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
    if (state.playbackSource == PlaybackSource.processed &&
        state.hasProcessedOutput) {
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
    };
  }

  String _videoOperationKey(VideoOperation operation) {
    return switch (operation) {
      VideoOperation.extractAudio => 'extract_audio',
      VideoOperation.compress => 'compress',
      VideoOperation.isolateVocals => 'isolate_vocals',
      VideoOperation.isolateMusic => 'isolate_music',
    };
  }

  Future<void> _loadProcessedOutput(String path) async {
    try {
      await _player.setFilePath(path);
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
    await _positionSubscription?.cancel();
    await _durationSubscription?.cancel();
    await _playerStateSubscription?.cancel();
    await _player.dispose();
    return super.close();
  }
}
