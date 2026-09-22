import 'package:soutnaqi/features/workspace/cubit/workspace_state.dart';
import 'package:soutnaqi/l10n/app_localizations.dart';

String separationProgressTitle(
  AppLocalizations l10n,
  WorkspaceState state,
) {
  return switch (state.processingPhase) {
    WorkspaceProcessingPhase.preparingAudio =>
      l10n.separationProgressPreparingAudio,
    WorkspaceProcessingPhase.extractingAudio =>
      l10n.separationProgressExtractingAudio,
    WorkspaceProcessingPhase.loadingModel => l10n.separationProgressLoadingModel,
    WorkspaceProcessingPhase.warmingUpEngine =>
      l10n.separationProgressWarmingUp,
    WorkspaceProcessingPhase.separating => _separatingTitle(l10n, state),
    WorkspaceProcessingPhase.encodingOutput =>
      l10n.separationProgressEncoding,
    WorkspaceProcessingPhase.finalizingVideo =>
      l10n.separationProgressFinalizingVideo,
    WorkspaceProcessingPhase.generic => l10n.toastLoading,
    WorkspaceProcessingPhase.none => l10n.toastLoading,
  };
}

String? separationProgressSubtitle(
  AppLocalizations l10n,
  WorkspaceState state,
) {
  if (!state.showSeparationKeepOpenHint) return null;
  return l10n.separationProgressKeepOpen;
}

String? separationProgressEta(
  AppLocalizations l10n,
  WorkspaceState state,
) {
  final eta = state.processingEta;
  if (eta == null) return null;
  if (eta.inSeconds < 45) {
    final seconds = eta.inSeconds < 5 ? 5 : ((eta.inSeconds + 4) ~/ 5) * 5;
    return l10n.separationProgressEtaSeconds(seconds);
  }
  final minutes = (eta.inSeconds / 60).ceil();
  return l10n.separationProgressEtaMinutes(minutes);
}

String _separatingTitle(AppLocalizations l10n, WorkspaceState state) {
  final current = state.processingChunkCurrent;
  final total = state.processingChunkTotal;
  if (current != null && total != null && total > 0) {
    return l10n.separationProgressSeparating(current, total);
  }
  return l10n.separationProgressSeparatingIndeterminate;
}
