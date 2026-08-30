import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum AppThemeMode { light, dark, system }

class SettingsState extends Equatable {
  const SettingsState({
    required this.themeMode,
    required this.locale,
    required this.isLoaded,
  });

  final AppThemeMode themeMode;
  final Locale locale;
  final bool isLoaded;

  ThemeMode get materialThemeMode => switch (themeMode) {
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
        AppThemeMode.system => ThemeMode.system,
      };

  SettingsState copyWith({
    AppThemeMode? themeMode,
    Locale? locale,
    bool? isLoaded,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  @override
  List<Object?> get props => [themeMode, locale, isLoaded];
}
