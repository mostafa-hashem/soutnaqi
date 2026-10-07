import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import 'package:soutnaqi/core/theme/magliss_context_colors.dart';
import 'package:soutnaqi/core/theme/magliss_typography.dart';
import 'package:soutnaqi/features/settings/cubit/settings_cubit.dart';
import 'package:soutnaqi/features/workspace/cubit/workspace_state.dart';
import 'package:soutnaqi/l10n/app_localizations.dart';

class WorkspacePlaybackSourceToggle extends StatelessWidget {
  const WorkspacePlaybackSourceToggle({
    super.key,
    required this.settingsCubit,
    required this.state,
    required this.onSourceChanged,
  });

  final SettingsCubit settingsCubit;
  final WorkspaceState state;
  final ValueChanged<PlaybackSource> onSourceChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isOriginal = state.playbackSource == PlaybackSource.original;
    final isProcessed = state.playbackSource == PlaybackSource.processed;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.surfacePrimary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                HugeIcon(
                  icon: HugeIconsStrokeRounded.checkmarkBadge01,
                  color: context.accentPrimary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.comparePureTitle,
                    style: font14W600(
                      settingsCubit: settingsCubit,
                      color: context.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: context.accentPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isProcessed
                        ? l10n.playbackPureNoMusic
                        : l10n.playbackOriginalWithMusic,
                    style: font12W500(
                      settingsCubit: settingsCubit,
                      color: context.accentPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.comparePureSubtitle,
              style: font12W400(
                settingsCubit: settingsCubit,
                color: context.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _CompareSegment(
                    settingsCubit: settingsCubit,
                    label: l10n.playbackOriginalWithMusic,
                    icon: HugeIconsStrokeRounded.musicNote03,
                    isSelected: isOriginal,
                    onTap: () => onSourceChanged(PlaybackSource.original),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CompareSegment(
                    settingsCubit: settingsCubit,
                    label: l10n.playbackPureNoMusic,
                    icon: HugeIconsStrokeRounded.aiVoice,
                    isSelected: isProcessed,
                    isPureAccent: true,
                    onTap: () => onSourceChanged(PlaybackSource.processed),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompareSegment extends StatelessWidget {
  const _CompareSegment({
    required this.settingsCubit,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.isPureAccent = false,
  });

  final SettingsCubit settingsCubit;
  final String label;
  final List<List<dynamic>> icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isPureAccent;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isSelected
        ? context.accentPrimary
        : context.inputFill;
    final contentColor = isSelected
        ? context.onAccent
        : context.textSecondary;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(
                icon: icon,
                color: contentColor,
                size: 16,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: font12W600(
                    settingsCubit: settingsCubit,
                    color: contentColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
