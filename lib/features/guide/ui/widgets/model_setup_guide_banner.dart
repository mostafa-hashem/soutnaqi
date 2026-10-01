import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import 'package:soutnaqi/core/theme/app_radii.dart';
import 'package:soutnaqi/core/theme/magliss_context_colors.dart';
import 'package:soutnaqi/core/theme/magliss_typography.dart';
import 'package:soutnaqi/features/separation/cubit/on_device_model_cubit.dart';
import 'package:soutnaqi/features/separation/cubit/on_device_model_state.dart';
import 'package:soutnaqi/features/settings/cubit/settings_cubit.dart';
import 'package:soutnaqi/features/shell/cubit/shell_cubit.dart';
import 'package:soutnaqi/features/shell/cubit/shell_tab.dart';
import 'package:soutnaqi/l10n/app_localizations.dart';

/// Interactive guided banner displayed on the Workspace screen to prompt
/// new users to navigate to Settings to prepare the offline AI model.
class WorkspaceModelGuideBanner extends StatelessWidget {
  const WorkspaceModelGuideBanner({
    super.key,
    required this.settingsCubit,
  });

  final SettingsCubit settingsCubit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.surfacePrimary,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: context.accentPrimary.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: context.accentPrimary.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.accentPrimary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: HugeIcon(
                  icon: HugeIconsStrokeRounded.sparkles,
                  color: context.accentPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.guideSettingsStepTitle,
                  style: font14W600(
                    settingsCubit: settingsCubit,
                    color: context.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: HugeIcon(
                  icon: HugeIconsStrokeRounded.cancel01,
                  color: context.textMuted,
                  size: 18,
                ),
                tooltip: l10n.guideSkip,
                onPressed: () => settingsCubit.completeModelGuide(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.guideSettingsStepDesc,
            style: font14W400(
              settingsCubit: settingsCubit,
              color: context.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 320;
              final actionButton = Material(
                color: context.accentPrimary,
                borderRadius: BorderRadius.circular(AppRadii.md),
                child: InkWell(
                  onTap: () {
                    context.read<ShellCubit>().selectTab(ShellTab.settings);
                  },
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: isNarrow ? MainAxisSize.max : MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.guideGoToSettings,
                          style: font14W600(
                            settingsCubit: settingsCubit,
                            color: context.onAccent,
                          ),
                        ),
                        const SizedBox(width: 6),
                        HugeIcon(
                          icon: isRtl
                              ? HugeIconsStrokeRounded.arrowLeft01
                              : HugeIconsStrokeRounded.arrowRight01,
                          color: context.onAccent,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              );

              final skipButton = TextButton(
                onPressed: () => settingsCubit.completeModelGuide(),
                child: Text(
                  l10n.guideSkip,
                  style: font14W500(
                    settingsCubit: settingsCubit,
                    color: context.textMuted,
                  ),
                ),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    actionButton,
                    const SizedBox(height: 4),
                    Center(child: skipButton),
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  skipButton,
                  const SizedBox(width: 8),
                  actionButton,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Interactive spotlight prompt in Settings screen highlighting the on-device
/// model download row and offering one-tap download or dismissal.
class SettingsModelGuideCard extends StatelessWidget {
  const SettingsModelGuideCard({
    super.key,
    required this.settingsCubit,
  });

  final SettingsCubit settingsCubit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.accentPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: context.accentPrimary,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: HugeIconsStrokeRounded.cloudDownload,
                color: context.accentPrimary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.guideModelStepTitle,
                  style: font14W600(
                    settingsCubit: settingsCubit,
                    color: context.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: HugeIcon(
                  icon: HugeIconsStrokeRounded.cancel01,
                  color: context.textMuted,
                  size: 18,
                ),
                tooltip: l10n.guideSkip,
                onPressed: () => settingsCubit.completeModelGuide(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.guideModelStepDesc,
            style: font14W400(
              settingsCubit: settingsCubit,
              color: context.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 320;
              final maybeLaterButton = TextButton(
                onPressed: () => settingsCubit.completeModelGuide(),
                child: Text(
                  l10n.guideMaybeLater,
                  style: font14W500(
                    settingsCubit: settingsCubit,
                    color: context.textMuted,
                  ),
                ),
              );

              final downloadButton = BlocBuilder<OnDeviceModelCubit, OnDeviceModelState>(
                builder: (context, modelState) {
                  final isDownloading =
                      modelState.status == OnDeviceModelStatus.downloading;

                  return Material(
                    color: context.accentPrimary,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    child: InkWell(
                      onTap: isDownloading
                          ? null
                          : () {
                              context.read<OnDeviceModelCubit>().download();
                              settingsCubit.completeModelGuide();
                            },
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: isNarrow ? MainAxisSize.max : MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            HugeIcon(
                              icon: HugeIconsStrokeRounded.cloudDownload,
                              color: context.onAccent,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l10n.guideDownloadNow,
                              style: font14W600(
                                settingsCubit: settingsCubit,
                                color: context.onAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    downloadButton,
                    const SizedBox(height: 4),
                    Center(child: maybeLaterButton),
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  maybeLaterButton,
                  const SizedBox(width: 8),
                  downloadButton,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
