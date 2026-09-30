import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import 'package:soutnaqi/core/theme/app_radii.dart';
import 'package:soutnaqi/core/theme/magliss_context_colors.dart';
import 'package:soutnaqi/core/theme/magliss_typography.dart';
import 'package:soutnaqi/core/widgets/soutnaqi_logo.dart';
import 'package:soutnaqi/features/settings/cubit/settings_cubit.dart';
import 'package:soutnaqi/features/settings/cubit/settings_state.dart';
import 'package:soutnaqi/l10n/app_localizations.dart';

class OnboardingWelcomeSlide extends StatelessWidget {
  const OnboardingWelcomeSlide({
    super.key,
    required this.settingsCubit,
  });

  final SettingsCubit settingsCubit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentState = settingsCubit.state;
    final currentLanguage = currentState.locale.languageCode;
    final currentTheme = currentState.themeMode;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 12),
          const SoutNaqiLogo(size: 72),
          const SizedBox(height: 18),
          Text(
            l10n.onboardingWelcomeTitle,
            textAlign: TextAlign.center,
            style: font24W700(
              settingsCubit: settingsCubit,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.onboardingWelcomeSubtitle,
            textAlign: TextAlign.center,
            style: font14W400(
              settingsCubit: settingsCubit,
              color: context.textSecondary,
            ),
          ),
          const SizedBox(height: 28),

          // Section 1: Language Selection
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              l10n.onboardingLanguageSelect,
              style: font14W600(
                settingsCubit: settingsCubit,
                color: context.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _OptionCard(
                  settingsCubit: settingsCubit,
                  title: 'العربية',
                  subtitle: 'Arabic',
                  icon: HugeIconsStrokeRounded.languageCircle,
                  isSelected: currentLanguage == 'ar',
                  onTap: () => settingsCubit.setLocale(const Locale('ar')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _OptionCard(
                  settingsCubit: settingsCubit,
                  title: 'English',
                  subtitle: 'الإنجليزية',
                  icon: HugeIconsStrokeRounded.globe02,
                  isSelected: currentLanguage == 'en',
                  onTap: () => settingsCubit.setLocale(const Locale('en')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Section 2: Theme Selection
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              l10n.onboardingThemeSelect,
              style: font14W600(
                settingsCubit: settingsCubit,
                color: context.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ThemeCard(
                  settingsCubit: settingsCubit,
                  title: l10n.themeDark,
                  icon: HugeIconsStrokeRounded.moon02,
                  isSelected: currentTheme == AppThemeMode.dark,
                  onTap: () => settingsCubit.setThemeMode(AppThemeMode.dark),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ThemeCard(
                  settingsCubit: settingsCubit,
                  title: l10n.themeLight,
                  icon: HugeIconsStrokeRounded.sun02,
                  isSelected: currentTheme == AppThemeMode.light,
                  onTap: () => settingsCubit.setThemeMode(AppThemeMode.light),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ThemeCard(
                  settingsCubit: settingsCubit,
                  title: l10n.themeSystem,
                  icon: HugeIconsStrokeRounded.smartPhone01,
                  isSelected: currentTheme == AppThemeMode.system,
                  onTap: () => settingsCubit.setThemeMode(AppThemeMode.system),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.settingsCubit,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final SettingsCubit settingsCubit;
  final String title;
  final String subtitle;
  final List<List<dynamic>> icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? context.accentPrimary : context.borderSubtle;
    final backgroundColor = isSelected
        ? context.accentPrimary.withValues(alpha: 0.08)
        : context.surfacePrimary;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Row(
            children: [
              HugeIcon(
                icon: icon,
                color: isSelected ? context.accentPrimary : context.textSecondary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: font14W600(
                        settingsCubit: settingsCubit,
                        color: isSelected
                            ? context.accentPrimary
                            : context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: font12W400(
                        settingsCubit: settingsCubit,
                        color: context.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                HugeIcon(
                  icon: HugeIconsStrokeRounded.checkmarkCircle02,
                  color: context.accentPrimary,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.settingsCubit,
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final SettingsCubit settingsCubit;
  final String title;
  final List<List<dynamic>> icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? context.accentPrimary : context.borderSubtle;
    final backgroundColor = isSelected
        ? context.accentPrimary.withValues(alpha: 0.08)
        : context.surfacePrimary;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(
                icon: icon,
                color: isSelected ? context.accentPrimary : context.textSecondary,
                size: 20,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: font12W600(
                  settingsCubit: settingsCubit,
                  color: isSelected ? context.accentPrimary : context.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
