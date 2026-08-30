import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soutnaqi/core/constants/layout_constants.dart';
import 'package:soutnaqi/core/theme/magliss_context_colors.dart';
import 'package:soutnaqi/core/theme/magliss_typography.dart';
import 'package:soutnaqi/features/history/cubit/history_cubit.dart';
import 'package:soutnaqi/features/history/ui/history_screen.dart';
import 'package:soutnaqi/features/settings/cubit/settings_cubit.dart';
import 'package:soutnaqi/features/settings/ui/settings_screen.dart';
import 'package:soutnaqi/features/shell/cubit/shell_cubit.dart';
import 'package:soutnaqi/features/shell/cubit/shell_state.dart';
import 'package:soutnaqi/features/shell/cubit/shell_tab.dart';
import 'package:soutnaqi/features/shell/ui/widgets/shell_bottom_nav.dart';
import 'package:soutnaqi/features/shell/ui/widgets/shell_sidebar.dart';
import 'package:soutnaqi/features/workspace/ui/workspace_screen.dart';
import 'package:soutnaqi/l10n/app_localizations.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsCubit = context.read<SettingsCubit>();
    final l10n = AppLocalizations.of(context);

    return BlocListener<ShellCubit, ShellState>(
      listenWhen: (previous, current) =>
          previous.selectedTab != current.selectedTab,
      listener: (context, state) {
        if (state.selectedTab != ShellTab.history) return;

        unawaited(context.read<HistoryCubit>().loadProjects());
      },
      child: BlocBuilder<ShellCubit, ShellState>(
        builder: (context, state) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final useSidebar = constraints.maxWidth >= kShellSidebarBreakpoint;
              final body = _ShellBody(selectedTab: state.selectedTab);

              if (useSidebar) {
                return Scaffold(
                  backgroundColor: context.webBackground,
                  body: SafeArea(
                    left: false,
                    right: false,
                    bottom: false,
                    child: Row(
                      children: [
                        ShellSidebar(
                          settingsCubit: settingsCubit,
                          selectedTab: state.selectedTab,
                          onTabSelected: context.read<ShellCubit>().selectTab,
                        ),
                        Expanded(child: body),
                      ],
                    ),
                  ),
                );
              }

              return Scaffold(
                backgroundColor: context.webBackground,
                appBar: AppBar(
                  backgroundColor: context.surfacePrimary,
                  surfaceTintColor: Colors.transparent,
                  title: Text(
                    _titleForTab(state.selectedTab, l10n),
                    style: font18W600(
                      settingsCubit: settingsCubit,
                      color: context.textPrimary,
                    ),
                  ),
                ),
                body: body,
                bottomNavigationBar: ShellBottomNav(
                  settingsCubit: settingsCubit,
                  selectedTab: state.selectedTab,
                  onTabSelected: context.read<ShellCubit>().selectTab,
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _titleForTab(ShellTab tab, AppLocalizations l10n) {
    return switch (tab) {
      ShellTab.workspace => l10n.navWorkspace,
      ShellTab.history => l10n.navHistory,
      ShellTab.settings => l10n.navSettings,
    };
  }
}

class _ShellBody extends StatelessWidget {
  const _ShellBody({required this.selectedTab});

  final ShellTab selectedTab;

  @override
  Widget build(BuildContext context) {
    return switch (selectedTab) {
      ShellTab.workspace => const WorkspaceScreen(),
      ShellTab.history => const HistoryScreen(),
      ShellTab.settings => const SettingsScreen(),
    };
  }
}
