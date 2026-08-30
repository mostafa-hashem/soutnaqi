import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soutnaqi/core/logging/app_log.dart';
import 'package:soutnaqi/features/settings/cubit/settings_state.dart';
import 'package:soutnaqi/features/settings/data/settings_repository.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({required SettingsRepository repository})
      : _repository = repository,
        super(
          const SettingsState(
            themeMode: AppThemeMode.system,
            locale: Locale('en'),
            isLoaded: false,
          ),
        );

  final SettingsRepository _repository;

  Future<void> load() async {
    appLog.d('🔍 Loading settings…');

    try {
      await _repository.init();
      if (isClosed) return;
      emit(
        state.copyWith(
          themeMode: _repository.loadThemeMode(),
          locale: _repository.loadLocale(),
          isLoaded: true,
        ),
      );
      appLog.d('✅ Settings loaded');
    } catch (error, stackTrace) {
      appLog.e(
        '❌ Settings load failed — using defaults',
        error: error,
        stackTrace: stackTrace,
      );
      if (isClosed) return;
      emit(state.copyWith(isLoaded: true));
    }
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    emit(state.copyWith(themeMode: mode));
    await _repository.saveThemeMode(mode);
  }

  Future<void> setLocale(Locale locale) async {
    emit(state.copyWith(locale: locale));
    await _repository.saveLocale(locale);
  }
}
