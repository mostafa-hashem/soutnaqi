import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import 'package:soutnaqi/core/config/app_env.dart';
import 'package:soutnaqi/core/theme/magliss_context_colors.dart';
import 'package:soutnaqi/core/theme/magliss_typography.dart';
import 'package:soutnaqi/features/separation/ui/separation_hint_l10n.dart';
import 'package:soutnaqi/features/settings/cubit/settings_cubit.dart';
import 'package:soutnaqi/features/video_processing/data/video_operation.dart';
import 'package:soutnaqi/features/workspace/cubit/workspace_state.dart';
import 'package:soutnaqi/l10n/app_localizations.dart';

class WorkspaceVideoTools extends StatelessWidget {
  const WorkspaceVideoTools({
    super.key,
    required this.settingsCubit,
    required this.state,
    required this.onExtractAudio,
    required this.onCompress,
    required this.onIsolateVocals,
    required this.onIsolateMusic,
  });

  final SettingsCubit settingsCubit;
  final WorkspaceState state;
  final VoidCallback onExtractAudio;
  final VoidCallback onCompress;
  final VoidCallback onIsolateVocals;
  final VoidCallback onIsolateMusic;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isBusy = state.isBusy;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.surfacePrimary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.videoProcessingTools,
              style: font16W600(
                settingsCubit: settingsCubit,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.videoProcessingHint,
              style: font12W400(
                settingsCubit: settingsCubit,
                color: context.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ToolButton(
                  settingsCubit: settingsCubit,
                  label: l10n.extractAudio,
                  icon: HugeIconsStrokeRounded.audioWave01,
                  isLoading: state.status == WorkspaceStatus.processing &&
                      state.activeVideoOperation ==
                          VideoOperation.extractAudio,
                  onPressed: isBusy ? null : onExtractAudio,
                ),
                _ToolButton(
                  settingsCubit: settingsCubit,
                  label: l10n.compressVideo,
                  icon: HugeIconsStrokeRounded.minimizeScreen,
                  isLoading: state.status == WorkspaceStatus.processing &&
                      state.activeVideoOperation == VideoOperation.compress,
                  onPressed: isBusy ? null : onCompress,
                ),
                _ToolButton(
                  settingsCubit: settingsCubit,
                  label: l10n.processIsolateVocals,
                  icon: HugeIconsStrokeRounded.aiVoice,
                  isLoading: state.status == WorkspaceStatus.processing &&
                      state.activeVideoOperation ==
                          VideoOperation.isolateVocals,
                  onPressed: isBusy ? null : onIsolateVocals,
                ),
                _ToolButton(
                  settingsCubit: settingsCubit,
                  label: l10n.processIsolateMusic,
                  icon: HugeIconsStrokeRounded.musicNote01,
                  isLoading: state.status == WorkspaceStatus.processing &&
                      state.activeVideoOperation ==
                          VideoOperation.isolateMusic,
                  onPressed: isBusy ? null : onIsolateMusic,
                ),
              ],
            ),
            if (AppEnv.isSeparationConfigured) ...[
              const SizedBox(height: 8),
              Text(
                separationHintFor(l10n),
                style: font12W400(
                  settingsCubit: settingsCubit,
                  color: context.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.settingsCubit,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
  });

  final SettingsCubit settingsCubit;
  final String label;
  final List<List<dynamic>> icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.inputFill,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.accentPrimary,
                  ),
                )
              else
                HugeIcon(
                  icon: icon,
                  color: context.accentPrimary,
                  size: 18,
                ),
              const SizedBox(width: 8),
              Text(
                label,
                style: font14W500(
                  settingsCubit: settingsCubit,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
