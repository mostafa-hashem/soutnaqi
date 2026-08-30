import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:soutnaqi/features/settings/cubit/settings_cubit.dart';
import 'package:soutnaqi/features/settings/cubit/settings_state.dart';
import 'package:soutnaqi/features/settings/ui/widgets/settings_segmented_control.dart';
import 'package:soutnaqi/l10n/app_localizations.dart';

class SettingsThemeSelector extends StatelessWidget {
  const SettingsThemeSelector({
    super.key,
    required this.settingsCubit,
  });

  final SettingsCubit settingsCubit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = context.watch<SettingsCubit>().state.themeMode;

    return SettingsSegmentedControl<AppThemeMode>(
      settingsCubit: settingsCubit,
      selected: current,
      onSelected: settingsCubit.setThemeMode,
      options: [
        SettingsSegmentedOption(
          value: AppThemeMode.light,
          label: l10n.themeLight,
        ),
        SettingsSegmentedOption(
          value: AppThemeMode.dark,
          label: l10n.themeDark,
        ),
        SettingsSegmentedOption(
          value: AppThemeMode.system,
          label: l10n.themeSystem,
        ),
      ],
    );
  }
}
