import 'package:flutter/material.dart';
import 'package:soutnaqi/core/theme/magliss_context_colors.dart';
import 'package:soutnaqi/core/theme/magliss_typography.dart';
import 'package:soutnaqi/features/audio_processing/data/audio_operation.dart';
import 'package:soutnaqi/features/settings/cubit/settings_cubit.dart';
import 'package:soutnaqi/features/workspace/cubit/workspace_state.dart';
import 'package:soutnaqi/l10n/app_localizations.dart';

class WorkspaceTrimPanel extends StatelessWidget {
  const WorkspaceTrimPanel({
    super.key,
    required this.settingsCubit,
    required this.state,
    required this.onTrimStartChanged,
    required this.onTrimEndChanged,
    required this.onApplyTrim,
  });

  final SettingsCubit settingsCubit;
  final WorkspaceState state;
  final ValueChanged<Duration> onTrimStartChanged;
  final ValueChanged<Duration> onTrimEndChanged;
  final VoidCallback onApplyTrim;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final durationMs = state.duration.inMilliseconds;
    if (durationMs <= 0) return const SizedBox.shrink();

    final startValue = state.trimStart.inMilliseconds / durationMs;
    final endValue = state.effectiveTrimEnd.inMilliseconds / durationMs;

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
              l10n.trimTitle,
              style: font16W600(
                settingsCubit: settingsCubit,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            RangeSlider(
              values: RangeValues(
                startValue.clamp(0, 1),
                endValue.clamp(0, 1),
              ),
              onChanged: state.isBusy
                  ? null
                  : (values) {
                      onTrimStartChanged(
                        Duration(
                          milliseconds: (values.start * durationMs).round(),
                        ),
                      );
                      onTrimEndChanged(
                        Duration(
                          milliseconds: (values.end * durationMs).round(),
                        ),
                      );
                    },
              activeColor: context.accentPrimary,
              inactiveColor: context.borderSubtle,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${l10n.trimStart} ${_format(state.trimStart)}',
                  style: font12W400(
                    settingsCubit: settingsCubit,
                    color: context.textMuted,
                  ),
                ),
                Text(
                  '${l10n.trimEnd} ${_format(state.effectiveTrimEnd)}',
                  style: font12W400(
                    settingsCubit: settingsCubit,
                    color: context.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Material(
              color: context.accentSecondary,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: state.isBusy ? null : onApplyTrim,
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 42,
                  width: double.infinity,
                  child: Center(
                    child: state.status == WorkspaceStatus.processing &&
                            state.activeOperation == AudioOperation.trim
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: context.surfacePrimary,
                            ),
                          )
                        : Text(
                            l10n.applyTrim,
                            style: font14W600(
                              settingsCubit: settingsCubit,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _format(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
