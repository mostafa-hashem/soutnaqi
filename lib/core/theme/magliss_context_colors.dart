import 'package:flutter/material.dart';

import 'package:soutnaqi/core/theme/magliss_color_tokens.dart';

extension MaglissContextColors on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  MaglissColorTokens get _tokens =>
      isDarkMode ? MaglissColorTokens.dark : MaglissColorTokens.light;

  Color get webBackground => _tokens.webBackground;
  Color get surfacePrimary => _tokens.surfacePrimary;
  Color get surfaceElevated => _tokens.surfaceElevated;
  Color get textPrimary => _tokens.textPrimary;
  Color get textSecondary => _tokens.textSecondary;
  Color get textMuted => _tokens.textMuted;
  Color get borderSubtle => _tokens.borderSubtle;
  Color get accentPrimary => _tokens.accentPrimary;
  Color get accentSecondary => _tokens.accentSecondary;
  Color get onAccent => _tokens.onAccent;
  Color get success => _tokens.success;
  Color get error => _tokens.error;
  Color get inputFill => _tokens.inputFill;
  Color get inputBorder => _tokens.inputBorder;
  Color get inputBorderFocused => _tokens.inputBorderFocused;
}
