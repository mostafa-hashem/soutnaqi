import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soutnaqi/core/errors/app_exception.dart';
import 'package:soutnaqi/core/errors/app_exception_l10n.dart';
import 'package:soutnaqi/core/layout/magliss_safe_insets.dart';
import 'package:soutnaqi/core/toast/app_toast.dart';
import 'package:soutnaqi/features/audio_processing/data/audio_operation.dart';
import 'package:soutnaqi/features/history/cubit/history_cubit.dart';
import 'package:soutnaqi/features/settings/cubit/settings_cubit.dart';
import 'package:soutnaqi/features/video_processing/data/video_operation.dart';
import 'package:soutnaqi/features/workspace/cubit/workspace_cubit.dart';
import 'package:soutnaqi/features/workspace/cubit/workspace_state.dart';
import 'package:soutnaqi/features/workspace/ui/widgets/workspace_canvas.dart';
import 'package:soutnaqi/features/workspace/ui/widgets/workspace_export_bar.dart';
import 'package:soutnaqi/features/workspace/ui/widgets/workspace_media_card.dart';
import 'package:soutnaqi/features/workspace/ui/widgets/workspace_player_bar.dart';
import 'package:soutnaqi/features/workspace/ui/widgets/workspace_processing_tools.dart';
import 'package:soutnaqi/features/workspace/ui/widgets/workspace_trim_panel.dart';
import 'package:soutnaqi/features/workspace/ui/widgets/workspace_video_preview.dart';
import 'package:soutnaqi/features/workspace/ui/widgets/workspace_video_tools.dart';
import 'package:soutnaqi/features/workspace/ui/widgets/workspace_waveform.dart';
import 'package:soutnaqi/l10n/app_localizations.dart';

class WorkspaceLoadedView extends StatelessWidget {
  const WorkspaceLoadedView({
    super.key,
    required this.settingsCubit,
    required this.state,
  });

  final SettingsCubit settingsCubit;
  final WorkspaceState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<WorkspaceCubit>();
    final media = state.media!;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: context.maglissShellScrollPadding(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  WorkspaceMediaCard(
                    settingsCubit: settingsCubit,
                    media: media,
                    formattedSize: _formatBytes(media.sizeBytes),
                    isBusy: state.isBusy,
                    onClear: () => _clearWorkspace(context),
                  ),
                  const SizedBox(height: 16),
                  WorkspaceCanvas(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: media.isAudio
                          ? WorkspaceWaveform(
                              state: state,
                              onSeekFraction: cubit.seekToFraction,
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                WorkspaceVideoPreview(
                                  settingsCubit: settingsCubit,
                                  media: media,
                                  state: state,
                                ),
                                if (state.hasProcessedOutput) ...[
                                  const SizedBox(height: 12),
                                  WorkspacePlaybackSourceToggle(
                                    settingsCubit: settingsCubit,
                                    state: state,
                                    onSourceChanged: cubit.switchPlaybackSource,
                                  ),
                                ],
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (media.isAudio) ...[
                    WorkspacePlayerBar(
                      settingsCubit: settingsCubit,
                      state: state,
                      onTogglePlayback: cubit.togglePlayback,
                      onSeek: cubit.seekTo,
                      onSourceChanged: cubit.switchPlaybackSource,
                    ),
                    const SizedBox(height: 16),
                    WorkspaceTrimPanel(
                      settingsCubit: settingsCubit,
                      state: state,
                      onTrimStartChanged: cubit.updateTrimStart,
                      onTrimEndChanged: cubit.updateTrimEnd,
                      onApplyTrim: () => _runToast(
                        context,
                        loading: l10n.trimLoading,
                        success: l10n.trimSuccess,
                        action: cubit.applyTrim,
                      ),
                    ),
                    const SizedBox(height: 16),
                    WorkspaceProcessingTools(
                      settingsCubit: settingsCubit,
                      state: state,
                      onNormalize: () => _runToast(
                        context,
                        loading: l10n.processNormalizeLoading,
                        success: l10n.processNormalizeSuccess,
                        action: () =>
                            cubit.processAudio(AudioOperation.normalize),
                      ),
                      onNoiseReduction: () => _runToast(
                        context,
                        loading: l10n.processNoiseLoading,
                        success: l10n.processNoiseSuccess,
                        action: () =>
                            cubit.processAudio(AudioOperation.noiseReduction),
                      ),
                      onIsolateVocals: () => _runToast(
                        context,
                        loading: l10n.processIsolateVocalsLoading,
                        success: l10n.processIsolateVocalsSuccess,
                        action: () =>
                            cubit.processAudio(AudioOperation.isolateVocals),
                      ),
                      onIsolateMusic: () => _runToast(
                        context,
                        loading: l10n.processIsolateMusicLoading,
                        success: l10n.processIsolateMusicSuccess,
                        action: () =>
                            cubit.processAudio(AudioOperation.isolateMusic),
                      ),
                    ),
                  ] else
                    WorkspaceVideoTools(
                      settingsCubit: settingsCubit,
                      state: state,
                      onExtractAudio: () => _runToast(
                        context,
                        loading: l10n.extractAudioLoading,
                        success: l10n.extractAudioSuccess,
                        action: () =>
                            cubit.processVideo(VideoOperation.extractAudio),
                      ),
                      onCompress: () => _runToast(
                        context,
                        loading: l10n.compressVideoLoading,
                        success: l10n.compressVideoSuccess,
                        action: () =>
                            cubit.processVideo(VideoOperation.compress),
                      ),
                      onIsolateVocals: () => _runToast(
                        context,
                        loading: l10n.processIsolateVocalsLoading,
                        success: l10n.processIsolateVocalsSuccess,
                        action: () =>
                            cubit.processVideo(VideoOperation.isolateVocals),
                      ),
                      onIsolateMusic: () => _runToast(
                        context,
                        loading: l10n.processIsolateMusicLoading,
                        success: l10n.processIsolateMusicSuccess,
                        action: () =>
                            cubit.processVideo(VideoOperation.isolateMusic),
                      ),
                    ),
                  const SizedBox(height: 16),
                  WorkspaceExportBar(
                    settingsCubit: settingsCubit,
                    state: state,
                    onSave: () => _save(context),
                    onShare: () => _runToast(
                      context,
                      loading: l10n.shareLoading,
                      success: l10n.shareSuccess,
                      action: cubit.shareExport,
                    ),
                    onSaveToHistory: () => _saveToHistory(context),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _clearWorkspace(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    await _runToast(
      context,
      loading: l10n.clearWorkspaceLoading,
      success: l10n.clearWorkspaceSuccess,
      action: context.read<WorkspaceCubit>().clearWorkspace,
    );
  }

  Future<void> _save(BuildContext context) async {
    final settingsCubit = context.read<SettingsCubit>();
    final l10n = AppLocalizations.of(context);

    AppToast.showLoading(
      context,
      settingsCubit: settingsCubit,
      message: l10n.saveLoading,
    );

    try {
      final saved = await context.read<WorkspaceCubit>().saveExport();
      if (!context.mounted) return;
      if (!saved) {
        AppToast.dismiss();
        return;
      }
      AppToast.showSuccess(
        context,
        settingsCubit: settingsCubit,
        message: l10n.saveSuccess,
      );
    } on AppException catch (error) {
      if (!context.mounted) return;
      AppToast.showFailure(
        context,
        settingsCubit: settingsCubit,
        message: appExceptionMessage(error, l10n),
      );
    }
  }

  Future<void> _saveToHistory(BuildContext context) async {
    final settingsCubit = context.read<SettingsCubit>();
    final l10n = AppLocalizations.of(context);

    AppToast.showLoading(
      context,
      settingsCubit: settingsCubit,
      message: l10n.saveToHistoryLoading,
    );

    try {
      final record = await context.read<WorkspaceCubit>().saveToHistory();
      if (!context.mounted) return;
      context.read<HistoryCubit>().addProjectLocally(record);
      AppToast.showSuccess(
        context,
        settingsCubit: settingsCubit,
        message: l10n.saveToHistorySuccess,
      );
    } on AppException catch (error) {
      if (!context.mounted) return;
      AppToast.showFailure(
        context,
        settingsCubit: settingsCubit,
        message: appExceptionMessage(error, l10n),
      );
    }
  }

  Future<void> _runToast(
    BuildContext context, {
    required String loading,
    required String success,
    required Future<void> Function() action,
  }) async {
    final settingsCubit = context.read<SettingsCubit>();
    final l10n = AppLocalizations.of(context);

    AppToast.showLoading(
      context,
      settingsCubit: settingsCubit,
      message: loading,
    );
    try {
      await action();
      if (!context.mounted) return;
      AppToast.showSuccess(
        context,
        settingsCubit: settingsCubit,
        message: success,
      );
    } on AppException catch (error) {
      if (!context.mounted) return;
      AppToast.showFailure(
        context,
        settingsCubit: settingsCubit,
        message: appExceptionMessage(error, l10n),
      );
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
