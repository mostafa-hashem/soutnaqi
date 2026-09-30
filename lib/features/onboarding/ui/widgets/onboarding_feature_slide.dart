import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:soutnaqi/core/theme/app_radii.dart';
import 'package:soutnaqi/core/theme/magliss_context_colors.dart';
import 'package:soutnaqi/core/theme/magliss_typography.dart';
import 'package:soutnaqi/features/settings/cubit/settings_cubit.dart';

class OnboardingFeatureItem {
  const OnboardingFeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String description;
}

class OnboardingFeatureSlide extends StatelessWidget {
  const OnboardingFeatureSlide({
    super.key,
    required this.settingsCubit,
    required this.icon,
    required this.badgeText,
    required this.title,
    required this.description,
    this.highlights = const [],
  });

  final SettingsCubit settingsCubit;
  final List<List<dynamic>> icon;
  final String badgeText;
  final String title;
  final String description;
  final List<OnboardingFeatureItem> highlights;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Large Icon container
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: context.accentPrimary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: context.accentPrimary.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Center(
              child: HugeIcon(
                icon: icon,
                color: context.accentPrimary,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: context.accentPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: context.accentPrimary.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              badgeText,
              style: font12W600(
                settingsCubit: settingsCubit,
                color: context.accentPrimary,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: font20W700(
              settingsCubit: settingsCubit,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 10),

          // Description
          Text(
            description,
            textAlign: TextAlign.center,
            style: font14W400(
              settingsCubit: settingsCubit,
              color: context.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Highlight Cards if available
          if (highlights.isNotEmpty) ...[
            Container(
              decoration: BoxDecoration(
                color: context.surfacePrimary,
                borderRadius: BorderRadius.circular(AppRadii.lg),
                border: Border.all(color: context.borderSubtle),
              ),
              child: Column(
                children: List.generate(highlights.length, (index) {
                  final item = highlights[index];
                  final isLast = index == highlights.length - 1;

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: context.accentPrimary
                                    .withValues(alpha: 0.1),
                                borderRadius:
                                    BorderRadius.circular(AppRadii.md),
                              ),
                              child: HugeIcon(
                                icon: item.icon,
                                color: context.accentPrimary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: font14W600(
                                      settingsCubit: settingsCubit,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.description,
                                    style: font12W400(
                                      settingsCubit: settingsCubit,
                                      color: context.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isLast)
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: context.borderSubtle,
                          indent: 52,
                        ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
