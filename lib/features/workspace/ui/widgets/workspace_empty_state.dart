import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import 'package:soutnaqi/core/theme/magliss_context_colors.dart';
import 'package:soutnaqi/core/theme/magliss_typography.dart';
import 'package:soutnaqi/features/settings/cubit/settings_cubit.dart';
import 'package:soutnaqi/l10n/app_localizations.dart';

class WorkspaceEmptyState extends StatelessWidget {
  const WorkspaceEmptyState({
    super.key,
    required this.settingsCubit,
    required this.onPickAudio,
    required this.onPickVideo,
    required this.onConvertVideoToAudio,
    required this.isBusy,
    this.showDropHint = false,
  });

  final SettingsCubit settingsCubit;
  final VoidCallback onPickAudio;
  final VoidCallback onPickVideo;
  final VoidCallback onConvertVideoToAudio;
  final bool isBusy;
  final bool showDropHint;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.hasBoundedHeight ? constraints.maxHeight : 0,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      HugeIcon(
                        icon: HugeIconsStrokeRounded.upload04,
                        color: context.accentPrimary,
                        size: 56,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.workspaceEmptyTitle,
                        textAlign: TextAlign.center,
                        style: font20W700(
                          settingsCubit: settingsCubit,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.workspaceEmptySubtitle,
                        textAlign: TextAlign.center,
                        style: font14W400(
                          settingsCubit: settingsCubit,
                          color: context.textSecondary,
                        ),
                      ),
                      if (showDropHint) ...[
                        const SizedBox(height: 12),
                        Text(
                          l10n.dropHint,
                          textAlign: TextAlign.center,
                          style: font12W500(
                            settingsCubit: settingsCubit,
                            color: context.accentPrimary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      LayoutBuilder(
                        builder: (context, actionConstraints) {
                          final isNarrow = actionConstraints.maxWidth < 320;
                          final audioBtn = _PickButton(
                            settingsCubit: settingsCubit,
                            label: l10n.pickAudio,
                            icon: HugeIconsStrokeRounded.audioWave01,
                            onPressed: isBusy ? null : onPickAudio,
                          );
                          final videoBtn = _PickButton(
                            settingsCubit: settingsCubit,
                            label: l10n.pickVideo,
                            icon: HugeIconsStrokeRounded.computerVideo,
                            onPressed: isBusy ? null : onPickVideo,
                            isSecondary: true,
                          );
                          final convertBtn = _PickButton(
                            settingsCubit: settingsCubit,
                            label: l10n.convertVideoToAudio,
                            icon: HugeIconsStrokeRounded.musicNote02,
                            onPressed: isBusy ? null : onConvertVideoToAudio,
                            isSecondary: true,
                            isHighlighted: true,
                          );

                          if (isNarrow) {
                            return Column(
                              children: [
                                audioBtn,
                                const SizedBox(height: 12),
                                videoBtn,
                                const SizedBox(height: 12),
                                convertBtn,
                              ],
                            );
                          }

                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(child: audioBtn),
                                  const SizedBox(width: 12),
                                  Expanded(child: videoBtn),
                                ],
                              ),
                              const SizedBox(height: 12),
                              convertBtn,
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PickButton extends StatelessWidget {
  const _PickButton({
    required this.settingsCubit,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isSecondary = false,
    this.isHighlighted = false,
  });

  final SettingsCubit settingsCubit;
  final String label;
  final List<List<dynamic>> icon;
  final VoidCallback? onPressed;
  final bool isSecondary;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final background = isHighlighted
        ? context.accentPrimary.withValues(alpha: 0.12)
        : isSecondary
            ? context.inputFill
            : context.accentPrimary;

    final foreground = isHighlighted
        ? context.accentPrimary
        : isSecondary
            ? context.textPrimary
            : context.onAccent;

    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isHighlighted
              ? context.accentPrimary.withValues(alpha: 0.4)
              : context.borderSubtle,
        ),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HugeIcon(icon: icon, color: foreground, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: font14W600(
                        settingsCubit: settingsCubit,
                        color: foreground,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
