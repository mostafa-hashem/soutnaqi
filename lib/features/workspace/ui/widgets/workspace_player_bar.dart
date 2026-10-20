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

class WorkspacePlayerBar extends StatefulWidget {
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
  State<WorkspacePlayerBar> createState() => _WorkspacePlayerBarState();
}

class _WorkspacePlayerBarState extends State<WorkspacePlayerBar> {
  double? _dragFraction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final maxMs = widget.state.duration.inMilliseconds;
    final progress =
        maxMs > 0 ? widget.state.position.inMilliseconds / maxMs : 0.0;
    final sliderValue = (_dragFraction ?? progress).clamp(0.0, 1.0);
    final isCompleted = maxMs > 0 && widget.state.position >= widget.state.duration;

    final currentDuration = _dragFraction != null
        ? Duration(milliseconds: (_dragFraction! * maxMs).round())
        : widget.state.position;

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
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        color: context.inputFill,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          onTap: widget.state.isPlayerReady
                              ? () {
                                  final target =
                                      widget.state.position - const Duration(seconds: 10);
                                  widget.onSeek(
                                    target < Duration.zero ? Duration.zero : target,
                                  );
                                }
                              : null,
                          borderRadius: BorderRadius.circular(18),
                          child: SizedBox(
                            width: 36,
                            height: 36,
                            child: Center(
                              child: HugeIcon(
                                icon: HugeIconsStrokeRounded.backward01,
                                color: context.textPrimary,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: context.accentPrimary,
                        borderRadius: BorderRadius.circular(24),
                        child: InkWell(
                          onTap: widget.state.isPlayerReady
                              ? widget.onTogglePlayback
                              : null,
                          borderRadius: BorderRadius.circular(24),
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Center(
                              child: HugeIcon(
                                icon: widget.state.isPlaying
                                    ? HugeIconsStrokeRounded.pause
                                    : (isCompleted
                                        ? HugeIconsStrokeRounded.replay
                                        : HugeIconsStrokeRounded.play),
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: context.inputFill,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          onTap: widget.state.isPlayerReady
                              ? () {
                                  final target =
                                      widget.state.position + const Duration(seconds: 10);
                                  final max = widget.state.duration;
                                  widget.onSeek(
                                    max > Duration.zero && target > max ? max : target,
                                  );
                                }
                              : null,
                          borderRadius: BorderRadius.circular(18),
                          child: SizedBox(
                            width: 36,
                            height: 36,
                            child: Center(
                              child: HugeIcon(
                                icon: HugeIconsStrokeRounded.forward01,
                                color: context.textPrimary,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.previewPlayback,
                        style: font14W600(
                          settingsCubit: widget.settingsCubit,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          '${_formatDuration(currentDuration)} / ${_formatDuration(widget.state.duration)}',
                          style: font12W400(
                            settingsCubit: widget.settingsCubit,
                            color: context.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: context.inputFill,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: widget.state.isPlayerReady
                        ? () async {
                            final selected = await showSpeedPickerSheet(
                              context,
                              settingsCubit: widget.settingsCubit,
                              currentSpeed: widget.state.playbackSpeed,
                            );
                            if (selected != null) {
                              widget.onSpeedChanged(selected);
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
                            '${widget.state.playbackSpeed}x',
                            style: font12W600(
                              settingsCubit: widget.settingsCubit,
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
            Directionality(
              textDirection: TextDirection.ltr,
              child: Slider(
                value: sliderValue,
                onChangeStart: widget.state.isPlayerReady
                    ? (val) => setState(() => _dragFraction = val)
                    : null,
                onChanged: widget.state.isPlayerReady
                    ? (val) => setState(() => _dragFraction = val)
                    : null,
                onChangeEnd: widget.state.isPlayerReady
                    ? (val) {
                        widget.onSeek(
                          Duration(milliseconds: (val * maxMs).round()),
                        );
                        setState(() => _dragFraction = null);
                      }
                    : null,
                activeColor: context.accentPrimary,
                inactiveColor: context.borderSubtle,
              ),
            ),
            if (widget.state.hasProcessedOutput) ...[
              const SizedBox(height: 8),
              WorkspacePlaybackSourceToggle(
                settingsCubit: widget.settingsCubit,
                state: widget.state,
                onSourceChanged: widget.onSourceChanged,
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
