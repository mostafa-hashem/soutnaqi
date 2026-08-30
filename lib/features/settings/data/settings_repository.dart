import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:soutnaqi/core/logging/app_log.dart';
import 'package:soutnaqi/core/storage/preferences_store.dart';
import 'package:soutnaqi/features/settings/cubit/settings_state.dart';

class SettingsRepository {
  SettingsRepository({PreferencesStore? store})
      : _store = store ?? PreferencesStore.instance;

  final PreferencesStore _store;
  SharedPreferences? _preferences;

  static const _themeModeKey = 'settings_theme_mode';
  static const _localeKey = 'settings_locale';

  Future<void> init() async {
    _preferences ??= await _store.preferences;
  }

  AppThemeMode loadThemeMode() {
    final value = _preferences?.getString(_themeModeKey);
    return AppThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => AppThemeMode.system,
    );
  }

  Locale loadLocale() {
    final value = _preferences?.getString(_localeKey);
    if (value == 'ar') {
      return const Locale('ar');
    }
    return const Locale('en');
  }

  Future<void> saveThemeMode(AppThemeMode mode) async {
    final preferences = await _store.preferences;
    await preferences.setString(_themeModeKey, mode.name);
    appLog.d('✅ Theme mode saved: ${mode.name}');
  }

  Future<void> saveLocale(Locale locale) async {
    final preferences = await _store.preferences;
    await preferences.setString(_localeKey, locale.languageCode);
    appLog.d('✅ Locale saved: ${locale.languageCode}');
  }
}
