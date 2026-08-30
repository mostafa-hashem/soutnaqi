import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import 'package:soutnaqi/core/theme/magliss_context_colors.dart';
import 'package:soutnaqi/core/theme/magliss_typography.dart';
import 'package:soutnaqi/core/widgets/soutnaqi_logo.dart';
import 'package:soutnaqi/features/settings/cubit/settings_cubit.dart';
import 'package:soutnaqi/features/shell/cubit/shell_tab.dart';
import 'package:soutnaqi/l10n/app_localizations.dart';

class ShellSidebar extends StatelessWidget {
  const ShellSidebar({
    super.key,
    required this.settingsCubit,
    required this.selectedTab,
    required this.onTabSelected,
  });

  final SettingsCubit settingsCubit;
  final ShellTab selectedTab;
  final ValueChanged<ShellTab> onTabSelected;

  static const double width = 240;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.surfacePrimary,
          border: Border(
            right: BorderSide(color: context.borderSubtle),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SoutNaqiLogo(
                  size: 32,
                  wordmark: l10n.appName,
                  wordmarkStyle: font16W600(
                    settingsCubit: settingsCubit,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                _SidebarItem(
                  settingsCubit: settingsCubit,
                  label: l10n.navWorkspace,
                  icon: HugeIconsStrokeRounded.computerVideo,
                  selected: selectedTab == ShellTab.workspace,
                  onTap: () => onTabSelected(ShellTab.workspace),
                ),
                const SizedBox(height: 8),
                _SidebarItem(
                  settingsCubit: settingsCubit,
                  label: l10n.navHistory,
                  icon: HugeIconsStrokeRounded.timeSchedule,
                  selected: selectedTab == ShellTab.history,
                  onTap: () => onTabSelected(ShellTab.history),
                ),
                const SizedBox(height: 8),
                _SidebarItem(
                  settingsCubit: settingsCubit,
                  label: l10n.navSettings,
                  icon: HugeIconsStrokeRounded.settings01,
                  selected: selectedTab == ShellTab.settings,
                  onTap: () => onTabSelected(ShellTab.settings),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
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
    final color = selected ? context.accentPrimary : context.textSecondary;

    return Material(
      color: selected
          ? context.accentPrimary.withValues(alpha: 0.1)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              HugeIcon(icon: icon, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: font14W500(
                    settingsCubit: settingsCubit,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
