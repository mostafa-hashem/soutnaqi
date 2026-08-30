import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import 'package:soutnaqi/core/layout/magliss_safe_insets.dart';
import 'package:soutnaqi/core/theme/magliss_context_colors.dart';
import 'package:soutnaqi/core/theme/magliss_typography.dart';
import 'package:soutnaqi/features/settings/cubit/settings_cubit.dart';
import 'package:soutnaqi/features/shell/cubit/shell_tab.dart';
import 'package:soutnaqi/l10n/app_localizations.dart';

class ShellBottomNav extends StatelessWidget {
  const ShellBottomNav({
    super.key,
    required this.settingsCubit,
    required this.selectedTab,
    required this.onTabSelected,
  });

  final SettingsCubit settingsCubit;
  final ShellTab selectedTab;
  final ValueChanged<ShellTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.surfacePrimary,
        border: Border(top: BorderSide(color: context.borderSubtle)),
      ),
      child: Padding(
        padding: context.maglissBottomNavPadding(),
        child: Row(
          children: [
            _NavItem(
              settingsCubit: settingsCubit,
              label: l10n.navWorkspace,
              icon: HugeIconsStrokeRounded.computerVideo,
              selected: selectedTab == ShellTab.workspace,
              onTap: () => onTabSelected(ShellTab.workspace),
            ),
            _NavItem(
              settingsCubit: settingsCubit,
              label: l10n.navHistory,
              icon: HugeIconsStrokeRounded.timeSchedule,
              selected: selectedTab == ShellTab.history,
              onTap: () => onTabSelected(ShellTab.history),
            ),
            _NavItem(
              settingsCubit: settingsCubit,
              label: l10n.navSettings,
              icon: HugeIconsStrokeRounded.settings01,
              selected: selectedTab == ShellTab.settings,
              onTap: () => onTabSelected(ShellTab.settings),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.settingsCubit,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final SettingsCubit settingsCubit;
  final String label;
  final List<List<dynamic>> icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? context.accentPrimary : context.textMuted;

    return Expanded(
      child: Material(
        color: selected
            ? context.accentPrimary.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                HugeIcon(icon: icon, color: color, size: 22),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: font12W500(
                    settingsCubit: settingsCubit,
                    color: color,
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
