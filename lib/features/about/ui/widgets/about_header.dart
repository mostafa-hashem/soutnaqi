import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import 'package:soutnaqi/core/constants/layout_constants.dart';
import 'package:soutnaqi/core/theme/app_radii.dart';
import 'package:soutnaqi/core/theme/magliss_context_colors.dart';
import 'package:soutnaqi/core/theme/magliss_typography.dart';
import 'package:soutnaqi/core/widgets/soutnaqi_logo.dart';
import 'package:soutnaqi/features/settings/cubit/settings_cubit.dart';
import 'package:soutnaqi/l10n/app_localizations.dart';

class AboutHeader extends StatelessWidget {
  const AboutHeader({
    super.key,
    required this.settingsCubit,
  });

  final SettingsCubit settingsCubit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.surfacePrimary,
            shape: BoxShape.circle,
            border: Border.all(
              color: context.accentPrimary.withValues(alpha: 0.25),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: context.accentPrimary.withValues(alpha: 0.08),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const SoutNaqiLogo(size: 64),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.appName,
          style: font24W700(
            settingsCubit: settingsCubit,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            l10n.aboutAppDescription,
            textAlign: TextAlign.center,
            style: font14W400(
              settingsCubit: settingsCubit,
              color: context.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _BadgeChip(
              settingsCubit: settingsCubit,
              icon: HugeIconsStrokeRounded.checkmarkBadge01,
              label: l10n.appVersion(kAppVersion),
            ),
            const SizedBox(width: 8),
            _BadgeChip(
              settingsCubit: settingsCubit,
              icon: HugeIconsStrokeRounded.aiVoice,
              label: l10n.aboutFeatureDedicatedTitle,
              isAccent: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({
    required this.settingsCubit,
    required this.icon,
    required this.label,
    this.isAccent = false,
  });

  final SettingsCubit settingsCubit;
  final List<List<dynamic>> icon;
  final String label;
  final bool isAccent;

  @override
  Widget build(BuildContext context) {
    final bgColor = isAccent
        ? context.accentPrimary.withValues(alpha: 0.12)
        : context.inputFill;
    final fgColor = isAccent ? context.accentPrimary : context.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(
          color: isAccent
              ? context.accentPrimary.withValues(alpha: 0.25)
              : context.borderSubtle,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: icon,
            color: fgColor,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: font12W500(
              settingsCubit: settingsCubit,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }
}
