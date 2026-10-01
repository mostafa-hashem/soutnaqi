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

class AboutTelegramCard extends StatelessWidget {
  const AboutTelegramCard({
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
        border: Border.all(
          color: const Color(0xFF229ED9).withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF229ED9).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: const HugeIcon(
                    icon: HugeIconsStrokeRounded.telegram,
                    color: Color(0xFF229ED9),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.telegramCommunityTitle,
                        style: font16W600(
                          settingsCubit: settingsCubit,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.telegramCommunitySubtitle,
                        style: font12W400(
                          settingsCubit: settingsCubit,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF229ED9),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                icon: const HugeIcon(
                  icon: HugeIconsStrokeRounded.telegram,
                  color: Colors.white,
                  size: 18,
                ),
                label: Text(
                  l10n.joinCommunityAction,
                  style: font14W600(
                    settingsCubit: settingsCubit,
                    color: Colors.white,
                  ),
                ),
                onPressed: () => launchAppUrl(kTelegramCommunityUrl),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
