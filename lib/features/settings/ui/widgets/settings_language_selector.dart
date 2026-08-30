import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:soutnaqi/features/settings/cubit/settings_cubit.dart';
import 'package:soutnaqi/features/settings/ui/widgets/settings_segmented_control.dart';
import 'package:soutnaqi/l10n/app_localizations.dart';

class SettingsLanguageSelector extends StatelessWidget {
  const SettingsLanguageSelector({
    super.key,
    required this.settingsCubit,
  });

  final SettingsCubit settingsCubit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = context.watch<SettingsCubit>().state.locale.languageCode;

    return SettingsSegmentedControl<String>(
      settingsCubit: settingsCubit,
      selected: current,
      onSelected: (code) => settingsCubit.setLocale(Locale(code)),
      options: [
        SettingsSegmentedOption(value: 'en', label: l10n.languageEnglish),
        SettingsSegmentedOption(value: 'ar', label: l10n.languageArabic),
      ],
    );
  }
}
