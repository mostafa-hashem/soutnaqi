import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum AppThemeMode { light, dark, system }

class SettingsState extends Equatable {
  const SettingsState({
    required this.themeMode,
    required this.locale,
    required this.isLoaded,
    this.hasCompletedOnboarding = false,
    this.hasCompletedModelGuide = false,
  });

  final AppThemeMode themeMode;
  final Locale locale;
  final bool isLoaded;
  final bool hasCompletedOnboarding;
  final bool hasCompletedModelGuide;

  ThemeMode get materialThemeMode => switch (themeMode) {
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
        AppThemeMode.system => ThemeMode.system,
      };

  SettingsState copyWith({
    AppThemeMode? themeMode,
    Locale? locale,
    bool? isLoaded,
    bool? hasCompletedOnboarding,
    bool? hasCompletedModelGuide,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      isLoaded: isLoaded ?? this.isLoaded,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      hasCompletedModelGuide:
          hasCompletedModelGuide ?? this.hasCompletedModelGuide,
    );
  }

  @override
  List<Object?> get props => [
        themeMode,
        locale,
        isLoaded,
        hasCompletedOnboarding,
        hasCompletedModelGuide,
      ];
}
