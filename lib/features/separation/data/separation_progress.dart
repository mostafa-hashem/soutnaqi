/// Stages reported while a [SeparationService] runs.
enum SeparationStage {
  preparingAudio,
  loadingModel,
  warmingUpEngine,
  separating,
  encodingOutput,
}

/// Progress snapshot for separation UI and logging.
class SeparationProgress {
  const SeparationProgress({
    required this.stage,
    this.progress,
    this.chunkIndex,
    this.totalChunks,
  });

  final SeparationStage stage;

  /// Overall progress for the current stage, 0.0–1.0 when known.
  final double? progress;
  final int? chunkIndex;
  final int? totalChunks;
}

typedef SeparationProgressCallback = void Function(SeparationProgress progress);
