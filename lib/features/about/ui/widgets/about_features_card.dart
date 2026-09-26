import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import 'package:soutnaqi/core/theme/app_radii.dart';
import 'package:soutnaqi/core/theme/magliss_context_colors.dart';
import 'package:soutnaqi/core/theme/magliss_typography.dart';
import 'package:soutnaqi/features/settings/cubit/settings_cubit.dart';
import 'package:soutnaqi/l10n/app_localizations.dart';

class AboutFeaturesCard extends StatelessWidget {
  const AboutFeaturesCard({
    super.key,
    required this.settingsCubit,
  });

  final SettingsCubit settingsCubit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.surfacePrimary,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.accentPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: HugeIcon(
                    icon: HugeIconsStrokeRounded.dashboardSquare01,
                    color: context.accentPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.aboutFeaturesTitle,
                    style: font16W600(
                      settingsCubit: settingsCubit,
                      color: context.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _FeatureItem(
              settingsCubit: settingsCubit,
              icon: HugeIconsStrokeRounded.aiVoice,
              title: l10n.aboutFeatureDedicatedTitle,
              description: l10n.aboutFeatureDedicatedDesc,
            ),
            const SizedBox(height: 14),
            _FeatureItem(
              settingsCubit: settingsCubit,
              icon: HugeIconsStrokeRounded.securityCheck,
              title: l10n.aboutFeaturePrivacyTitle,
              description: l10n.aboutFeaturePrivacyDesc,
            ),
            const SizedBox(height: 14),
            _FeatureItem(
              settingsCubit: settingsCubit,
              icon: HugeIconsStrokeRounded.computerVideo,
              title: l10n.aboutFeatureMediaTitle,
              description: l10n.aboutFeatureMediaDesc,
            ),
            const SizedBox(height: 14),
            _FeatureItem(
              settingsCubit: settingsCubit,
              icon: HugeIconsStrokeRounded.slidersHorizontal,
              title: l10n.aboutFeatureToolsTitle,
              description: l10n.aboutFeatureToolsDesc,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.settingsCubit,
    required this.icon,
    required this.title,
    required this.description,
  });

  final SettingsCubit settingsCubit;
  final List<List<dynamic>> icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: context.inputFill,
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border.all(color: context.borderSubtle),
          ),
          child: HugeIcon(
            icon: icon,
            color: context.accentPrimary,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: font14W600(
                  settingsCubit: settingsCubit,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: font12W400(
                  settingsCubit: settingsCubit,
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
