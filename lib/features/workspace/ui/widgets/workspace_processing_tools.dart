import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import 'package:soutnaqi/core/config/app_env.dart';
import 'package:soutnaqi/core/theme/magliss_context_colors.dart';
import 'package:soutnaqi/core/theme/magliss_typography.dart';
import 'package:soutnaqi/features/audio_processing/data/audio_operation.dart';
import 'package:soutnaqi/features/separation/ui/separation_hint_l10n.dart';
import 'package:soutnaqi/features/settings/cubit/settings_cubit.dart';
import 'package:soutnaqi/features/workspace/cubit/workspace_state.dart';
import 'package:soutnaqi/l10n/app_localizations.dart';

class WorkspaceProcessingTools extends StatelessWidget {
  const WorkspaceProcessingTools({
    super.key,
    required this.settingsCubit,
    required this.state,
    required this.onNormalize,
    required this.onNoiseReduction,
    required this.onIsolateVocals,
    required this.onIsolateMusic,
  });

  final SettingsCubit settingsCubit;
  final WorkspaceState state;
  final VoidCallback onNormalize;
  final VoidCallback onNoiseReduction;
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
              l10n.processingTools,
              style: font16W600(
                settingsCubit: settingsCubit,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ToolButton(
                  settingsCubit: settingsCubit,
                  label: l10n.processNormalize,
                  icon: HugeIconsStrokeRounded.volumeHigh,
                  isLoading: state.status == WorkspaceStatus.processing &&
                      state.activeOperation == AudioOperation.normalize,
                  onPressed: isBusy ? null : onNormalize,
                ),
                _ToolButton(
                  settingsCubit: settingsCubit,
                  label: l10n.processNoiseReduction,
                  icon: HugeIconsStrokeRounded.magicWand01,
                  isLoading: state.status == WorkspaceStatus.processing &&
                      state.activeOperation == AudioOperation.noiseReduction,
                  onPressed: isBusy ? null : onNoiseReduction,
                ),
                _ToolButton(
                  settingsCubit: settingsCubit,
                  label: l10n.processIsolateVocals,
                  icon: HugeIconsStrokeRounded.aiVoice,
                  isLoading: state.status == WorkspaceStatus.processing &&
                      state.activeOperation == AudioOperation.isolateVocals,
                  onPressed: isBusy ? null : onIsolateVocals,
                ),
                _ToolButton(
                  settingsCubit: settingsCubit,
                  label: l10n.processIsolateMusic,
                  icon: HugeIconsStrokeRounded.musicNote01,
                  isLoading: state.status == WorkspaceStatus.processing &&
                      state.activeOperation == AudioOperation.isolateMusic,
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
            if (state.hasProcessedOutput) ...[
              const SizedBox(height: 12),
              Text(
                l10n.processingCompleteHint,
                style: font12W400(
                  settingsCubit: settingsCubit,
                  color: context.success,
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
