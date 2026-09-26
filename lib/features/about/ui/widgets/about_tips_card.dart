import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import 'package:soutnaqi/core/theme/app_radii.dart';
import 'package:soutnaqi/core/theme/magliss_context_colors.dart';
import 'package:soutnaqi/core/theme/magliss_typography.dart';
import 'package:soutnaqi/features/settings/cubit/settings_cubit.dart';
import 'package:soutnaqi/l10n/app_localizations.dart';

class AboutTipsCard extends StatelessWidget {
  const AboutTipsCard({
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
                    icon: HugeIconsStrokeRounded.bulb,
                    color: context.accentPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.aboutTipsTitle,
                    style: font16W600(
                      settingsCubit: settingsCubit,
                      color: context.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _TipRow(
              settingsCubit: settingsCubit,
              index: '1',
              text: l10n.aboutTip1,
            ),
            const SizedBox(height: 10),
            _TipRow(
              settingsCubit: settingsCubit,
              index: '2',
              text: l10n.aboutTip2,
            ),
            const SizedBox(height: 10),
            _TipRow(
              settingsCubit: settingsCubit,
              index: '3',
              text: l10n.aboutTip3,
            ),
          ],
        ),
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({
    required this.settingsCubit,
    required this.index,
    required this.text,
  });

  final SettingsCubit settingsCubit;
  final String index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          margin: const EdgeInsets.only(top: 1),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.accentPrimary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Text(
            index,
            style: font12W500(
              settingsCubit: settingsCubit,
              color: context.accentPrimary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: font13W400(
              settingsCubit: settingsCubit,
              color: context.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

TextStyle font13W400({
  required SettingsCubit settingsCubit,
  Color? color,
}) =>
    font14W400(
      settingsCubit: settingsCubit,
      color: color,
    ).copyWith(fontSize: 13, height: 1.45);
