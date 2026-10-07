import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import 'package:soutnaqi/core/theme/magliss_context_colors.dart';
import 'package:soutnaqi/core/theme/magliss_typography.dart';
import 'package:soutnaqi/features/settings/cubit/settings_cubit.dart';
import 'package:soutnaqi/features/workspace/cubit/workspace_state.dart';
import 'package:soutnaqi/features/workspace/ui/widgets/speed_picker_sheet.dart';
import 'package:soutnaqi/features/workspace/ui/widgets/workspace_playback_source_toggle.dart';
import 'package:soutnaqi/l10n/app_localizations.dart';

export 'package:soutnaqi/features/workspace/ui/widgets/workspace_playback_source_toggle.dart';

class WorkspacePlayerBar extends StatelessWidget {
  const WorkspacePlayerBar({
    super.key,
    required this.settingsCubit,
    required this.state,
    required this.onTogglePlayback,
    required this.onSeek,
    required this.onSourceChanged,
    required this.onSpeedChanged,
  });

  final SettingsCubit settingsCubit;
  final WorkspaceState state;
  final VoidCallback onTogglePlayback;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<PlaybackSource> onSourceChanged;
  final ValueChanged<double> onSpeedChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final maxMs = state.duration.inMilliseconds;
    final value = maxMs > 0 ? state.position.inMilliseconds / maxMs : 0.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.surfacePrimary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Material(
                  color: context.accentPrimary,
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    onTap: state.isPlayerReady ? onTogglePlayback : null,
                    borderRadius: BorderRadius.circular(24),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: HugeIcon(
                          icon: state.isPlaying
                              ? HugeIconsStrokeRounded.pause
                              : HugeIconsStrokeRounded.play,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.previewPlayback,
                        style: font14W600(
                          settingsCubit: settingsCubit,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatDuration(state.position)} / ${_formatDuration(state.duration)}',
                        style: font12W400(
                          settingsCubit: settingsCubit,
                          color: context.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: context.inputFill,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: state.isPlayerReady
                        ? () async {
                            final selected = await showSpeedPickerSheet(
                              context,
                              settingsCubit: settingsCubit,
                              currentSpeed: state.playbackSpeed,
                            );
                            if (selected != null) {
                              onSpeedChanged(selected);
                            }
                          }
                        : null,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HugeIcon(
                            icon: HugeIconsStrokeRounded.dashboardSquare01,
                            color: context.accentPrimary,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${state.playbackSpeed}x',
                            style: font12W600(
                              settingsCubit: settingsCubit,
                              color: context.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Slider(
              value: value.clamp(0, 1),
              onChanged: state.isPlayerReady
                  ? (next) => onSeek(
                        Duration(
                          milliseconds: (next * maxMs).round(),
                        ),
                      )
                  : null,
              activeColor: context.accentPrimary,
              inactiveColor: context.borderSubtle,
            ),
            if (state.hasProcessedOutput) ...[
              const SizedBox(height: 8),
              WorkspacePlaybackSourceToggle(
                settingsCubit: settingsCubit,
                state: state,
                onSourceChanged: onSourceChanged,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
