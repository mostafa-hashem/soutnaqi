import 'package:flutter/material.dart';

import 'package:soutnaqi/core/theme/app_radii.dart';
import 'package:soutnaqi/core/theme/magliss_color_tokens.dart';
import 'package:soutnaqi/core/theme/magliss_typography.dart';

class MaglissTheme {
  MaglissTheme._();

  static ThemeData light({required Locale locale}) => _build(
        tokens: MaglissColorTokens.light,
        brightness: Brightness.light,
        locale: locale,
      );

  static ThemeData dark({required Locale locale}) => _build(
        tokens: MaglissColorTokens.dark,
        brightness: Brightness.dark,
        locale: locale,
      );

  static ThemeData _build({
    required MaglissColorTokens tokens,
    required Brightness brightness,
    required Locale locale,
  }) {
    const radius = AppRadii.md;
    final baseTextTheme = ThemeData(brightness: brightness).textTheme.apply(
          fontFamily: fontFamilyFor(locale),
          bodyColor: tokens.textPrimary,
          displayColor: tokens.textPrimary,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: fontFamilyFor(locale),
      scaffoldBackgroundColor: tokens.webBackground,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: tokens.accentPrimary,
        onPrimary: tokens.onAccent,
        secondary: tokens.accentSecondary,
        onSecondary: Colors.white,
        error: tokens.error,
        onError: Colors.white,
        surface: tokens.surfacePrimary,
        onSurface: tokens.textPrimary,
      ),
      dividerColor: tokens.borderSubtle,
      textTheme: baseTextTheme,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: tokens.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: tokens.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: tokens.inputBorderFocused, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: tokens.error),
        ),
      ),
    );
  }
}
