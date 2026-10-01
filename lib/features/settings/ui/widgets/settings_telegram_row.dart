import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import 'package:soutnaqi/core/constants/layout_constants.dart';
import 'package:soutnaqi/core/theme/app_radii.dart';
import 'package:soutnaqi/core/theme/magliss_context_colors.dart';
import 'package:soutnaqi/core/theme/magliss_typography.dart';
import 'package:soutnaqi/core/utils/url_launcher_helper.dart';
import 'package:soutnaqi/features/settings/cubit/settings_cubit.dart';
import 'package:soutnaqi/l10n/app_localizations.dart';

class SettingsTelegramRow extends StatelessWidget {
  const SettingsTelegramRow({
    super.key,
    required this.settingsCubit,
  });

  final SettingsCubit settingsCubit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        onTap: () => launchAppUrl(kTelegramCommunityUrl),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF229ED9).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const HugeIcon(
                  icon: HugeIconsStrokeRounded.telegram,
                  color: Color(0xFF229ED9),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          l10n.telegramCommunityTitle,
                          style: font16W600(
                            settingsCubit: settingsCubit,
                            color: context.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: context.accentPrimary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            l10n.joinCommunityAction,
                            style: font10W400(
                              settingsCubit: settingsCubit,
                              color: context.accentPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.telegramCommunitySubtitle,
                      style: font12W400(
                        settingsCubit: settingsCubit,
                        color: context.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              HugeIcon(
                icon: isRtl
                    ? HugeIconsStrokeRounded.arrowLeft01
                    : HugeIconsStrokeRounded.arrowRight01,
                color: context.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
