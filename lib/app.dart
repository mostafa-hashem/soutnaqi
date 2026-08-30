import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:soutnaqi/core/theme/magliss_theme.dart';
import 'package:soutnaqi/features/settings/cubit/settings_cubit.dart';
import 'package:soutnaqi/features/settings/cubit/settings_state.dart';
import 'package:soutnaqi/features/settings/data/settings_repository.dart';
import 'package:soutnaqi/features/shell/ui/app_bootstrap.dart';
import 'package:soutnaqi/l10n/app_localizations.dart';

class SoutNaqiApp extends StatelessWidget {
  const SoutNaqiApp({super.key});

  static const _localizationsDelegates = [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SettingsCubit(repository: SettingsRepository())..load(),
      child: BlocBuilder<SettingsCubit, SettingsState>(
        buildWhen: (previous, current) =>
            previous.themeMode != current.themeMode ||
            previous.locale != current.locale,
        builder: (context, state) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            onGenerateTitle: (context) => AppLocalizations.of(context).appName,
            locale: state.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: _localizationsDelegates,
            themeMode: state.materialThemeMode,
            theme: MaglissTheme.light(locale: state.locale),
            darkTheme: MaglissTheme.dark(locale: state.locale),
            home: const AppBootstrap(),
          );
        },
      ),
    );
  }
}
