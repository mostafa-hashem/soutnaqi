import 'package:equatable/equatable.dart';

import 'package:soutnaqi/features/audio_processing/data/audio_operation.dart';
import 'package:soutnaqi/features/media/data/models/media_file.dart';
import 'package:soutnaqi/features/video_processing/data/video_operation.dart';

enum WorkspaceProcessingPhase {
  none,
  preparingAudio,
  extractingAudio,
  loadingModel,
  warmingUpEngine,
  separating,
  encodingOutput,
  finalizingVideo,
  generic,
}

enum WorkspaceStatus {
  empty,
  picking,
  ready,
  processing,
  processed,
}

enum PlaybackSource { original, processed }

class WorkspaceState extends Equatable {
  const WorkspaceState({
    this.status = WorkspaceStatus.empty,
    this.media,
    this.processedPath,
    this.activeOperation,
    this.activeVideoOperation,
    this.playbackSource = PlaybackSource.original,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isPlayerReady = false,
    this.waveformPeaks = const [],
    this.isWaveformLoading = false,
    this.trimStart = Duration.zero,
    this.trimEnd = Duration.zero,
    this.isSharing = false,
    this.isSaving = false,
    this.isSavingToHistory = false,
    this.historyPath,
    this.lastOperation,
    this.processingPhase = WorkspaceProcessingPhase.none,
    this.processingProgress,
    this.processingChunkCurrent,
    this.processingChunkTotal,
  });

  final WorkspaceStatus status;
  final MediaFile? media;
  final String? processedPath;
  final AudioOperation? activeOperation;
  final VideoOperation? activeVideoOperation;
  final PlaybackSource playbackSource;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final bool isPlayerReady;
  final List<double> waveformPeaks;
  final bool isWaveformLoading;
  final Duration trimStart;
  final Duration trimEnd;
  final bool isSharing;
  final bool isSaving;
  final bool isSavingToHistory;
  final String? historyPath;
  final String? lastOperation;
  final WorkspaceProcessingPhase processingPhase;
  final double? processingProgress;
  final int? processingChunkCurrent;
  final int? processingChunkTotal;

  bool get hasProcessingOverlay =>
      status == WorkspaceStatus.processing &&
      processingPhase != WorkspaceProcessingPhase.none;

  bool get showSeparationKeepOpenHint =>
      processingPhase == WorkspaceProcessingPhase.warmingUpEngine ||
      processingPhase == WorkspaceProcessingPhase.separating ||
      processingPhase == WorkspaceProcessingPhase.loadingModel;

  bool get hasMedia => media != null;
  bool get hasProcessedOutput =>
      processedPath != null && processedPath!.isNotEmpty;
  bool get hasWaveform => waveformPeaks.isNotEmpty;
  bool get canProcess => media?.isAudio ?? false;
  bool get isBusy =>
      status == WorkspaceStatus.picking ||
      status == WorkspaceStatus.processing ||
      isSharing ||
      isSaving ||
      isSavingToHistory;

  Duration get effectiveTrimEnd {
    if (trimEnd > Duration.zero) return trimEnd;
    return duration;
  }

  WorkspaceState copyWith({
    WorkspaceStatus? status,
    MediaFile? media,
    String? processedPath,
    AudioOperation? activeOperation,
    VideoOperation? activeVideoOperation,
    PlaybackSource? playbackSource,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    bool? isPlayerReady,
    List<double>? waveformPeaks,
    bool? isWaveformLoading,
    Duration? trimStart,
    Duration? trimEnd,
    bool? isSharing,
    bool? isSaving,
    bool? isSavingToHistory,
    String? historyPath,
    String? lastOperation,
    WorkspaceProcessingPhase? processingPhase,
    double? processingProgress,
    int? processingChunkCurrent,
    int? processingChunkTotal,
    bool clearMedia = false,
    bool clearProcessed = false,
    bool clearOperation = false,
    bool clearVideoOperation = false,
    bool clearHistoryPath = false,
    bool clearLastOperation = false,
    bool clearProcessingOverlay = false,
    bool updateProcessingProgress = false,
    bool clearProcessingChunks = false,
  }) {
    return WorkspaceState(
      status: status ?? this.status,
      media: clearMedia ? null : (media ?? this.media),
      processedPath:
          clearProcessed ? null : (processedPath ?? this.processedPath),
      activeOperation: clearOperation
          ? null
          : (activeOperation ?? this.activeOperation),
      activeVideoOperation: clearVideoOperation
          ? null
          : (activeVideoOperation ?? this.activeVideoOperation),
      playbackSource: playbackSource ?? this.playbackSource,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isPlayerReady: isPlayerReady ?? this.isPlayerReady,
      waveformPeaks: waveformPeaks ?? this.waveformPeaks,
      isWaveformLoading: isWaveformLoading ?? this.isWaveformLoading,
      trimStart: trimStart ?? this.trimStart,
      trimEnd: trimEnd ?? this.trimEnd,
      isSharing: isSharing ?? this.isSharing,
      isSaving: isSaving ?? this.isSaving,
      isSavingToHistory: isSavingToHistory ?? this.isSavingToHistory,
      historyPath: clearHistoryPath ? null : (historyPath ?? this.historyPath),
      lastOperation:
          clearLastOperation ? null : (lastOperation ?? this.lastOperation),
      processingPhase: clearProcessingOverlay
          ? WorkspaceProcessingPhase.none
          : (processingPhase ?? this.processingPhase),
      processingProgress: clearProcessingOverlay
          ? null
          : (updateProcessingProgress
              ? processingProgress
              : this.processingProgress),
      processingChunkCurrent: clearProcessingOverlay || clearProcessingChunks
          ? null
          : (processingChunkCurrent ?? this.processingChunkCurrent),
      processingChunkTotal: clearProcessingOverlay || clearProcessingChunks
          ? null
          : (processingChunkTotal ?? this.processingChunkTotal),
    );
  }

  @override
  List<Object?> get props => [
        status,
        media,
        processedPath,
        activeOperation,
        activeVideoOperation,
        playbackSource,
        isPlaying,
        position,
        duration,
        isPlayerReady,
        waveformPeaks,
        isWaveformLoading,
        trimStart,
        trimEnd,
        isSharing,
        isSaving,
        isSavingToHistory,
        historyPath,
        lastOperation,
        processingPhase,
        processingProgress,
        processingChunkCurrent,
        processingChunkTotal,
      ];
}
