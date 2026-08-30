import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import 'package:soutnaqi/core/constants/layout_constants.dart';
import 'package:soutnaqi/core/layout/magliss_safe_insets.dart';
import 'package:soutnaqi/core/theme/app_radii.dart';
import 'package:soutnaqi/core/theme/magliss_context_colors.dart';
import 'package:soutnaqi/core/theme/magliss_typography.dart';
import 'package:soutnaqi/core/widgets/soutnaqi_logo.dart';
import 'package:soutnaqi/features/settings/cubit/settings_cubit.dart';
import 'package:soutnaqi/features/settings/ui/widgets/settings_language_selector.dart';
import 'package:soutnaqi/features/settings/ui/widgets/settings_theme_selector.dart';
import 'package:soutnaqi/l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsCubit = context.read<SettingsCubit>();
    final l10n = AppLocalizations.of(context);

    return ColoredBox(
      color: context.webBackground,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showPageTitle =
              constraints.maxWidth >= kShellSidebarBreakpoint;

          return SingleChildScrollView(
            padding: context.maglissShellScrollPadding(),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showPageTitle) ...[
                      Text(
                        l10n.settingsTitle,
                        style: font24W700(
                          settingsCubit: settingsCubit,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
                    _SectionLabel(
                      settingsCubit: settingsCubit,
                      label: l10n.appearanceSection,
                    ),
                    _SettingsCard(
                      children: [
                        _PreferenceRow(
                          settingsCubit: settingsCubit,
                          icon: HugeIconsStrokeRounded.paintBoard,
                          title: l10n.themeSection,
                          control: SettingsThemeSelector(
                            settingsCubit: settingsCubit,
                          ),
                        ),
                        _CardDivider(),
                        _PreferenceRow(
                          settingsCubit: settingsCubit,
                          icon: HugeIconsStrokeRounded.languageSquare,
                          title: l10n.languageLabel,
                          control: SettingsLanguageSelector(
                            settingsCubit: settingsCubit,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _SectionLabel(
                      settingsCubit: settingsCubit,
                      label: l10n.aboutSection,
                    ),
                    _SettingsCard(
                      children: [
                        _AboutRow(settingsCubit: settingsCubit),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.settingsCubit,
    required this.label,
  });

  final SettingsCubit settingsCubit;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
      child: Text(
        label,
        style: font12W500(
          settingsCubit: settingsCubit,
          color: context.textMuted,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.surfacePrimary,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Column(children: children),
    );
  }
}

class _CardDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: context.borderSubtle,
      indent: 52,
    );
  }
}

class _PreferenceRow extends StatelessWidget {
  const _PreferenceRow({
    required this.settingsCubit,
    required this.icon,
    required this.title,
    required this.control,
  });

  final SettingsCubit settingsCubit;
  final List<List<dynamic>> icon;
  final String title;
  final Widget control;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: icon,
                color: context.accentPrimary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: font14W600(
                    settingsCubit: settingsCubit,
                    color: context.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          control,
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({required this.settingsCubit});

  final SettingsCubit settingsCubit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        children: [
          const SoutNaqiLogo(size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.appName,
                  style: font16W600(
                    settingsCubit: settingsCubit,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.appTagline,
                  style: font12W400(
                    settingsCubit: settingsCubit,
                    color: context.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.appVersion(kAppVersion),
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
    );
  }
}
