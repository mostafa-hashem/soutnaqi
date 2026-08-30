import 'package:flutter/material.dart';

class MaglissColorTokens {
  const MaglissColorTokens({
    required this.webBackground,
    required this.surfacePrimary,
    required this.surfaceElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.borderSubtle,
    required this.accentPrimary,
    required this.accentSecondary,
    required this.onAccent,
    required this.success,
    required this.error,
    required this.inputFill,
    required this.inputBorder,
    required this.inputBorderFocused,
  });

  final Color webBackground;
  final Color surfacePrimary;
  final Color surfaceElevated;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color borderSubtle;
  final Color accentPrimary;
  final Color accentSecondary;
  final Color onAccent;
  final Color success;
  final Color error;
  final Color inputFill;
  final Color inputBorder;
  final Color inputBorderFocused;

  static const MaglissColorTokens light = MaglissColorTokens(
    webBackground: Color(0xFFF4F6FA),
    surfacePrimary: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF374151),
    textMuted: Color(0xFF6B7280),
    borderSubtle: Color(0xFFE5E7EB),
    accentPrimary: Color(0xFF2563EB),
    accentSecondary: Color(0xFF7C3AED),
    onAccent: Color(0xFFFFFFFF),
    success: Color(0xFF059669),
    error: Color(0xFFDC2626),
    inputFill: Color(0xFFF9FAFB),
    inputBorder: Color(0xFFD1D5DB),
    inputBorderFocused: Color(0xFF2563EB),
  );

  static const MaglissColorTokens dark = MaglissColorTokens(
    webBackground: Color(0xFF0B0F17),
    surfacePrimary: Color(0xFF111827),
    surfaceElevated: Color(0xFF1F2937),
    textPrimary: Color(0xFFF9FAFB),
    textSecondary: Color(0xFFD1D5DB),
    textMuted: Color(0xFF9CA3AF),
    borderSubtle: Color(0xFF374151),
    accentPrimary: Color(0xFF60A5FA),
    accentSecondary: Color(0xFFA78BFA),
    onAccent: Color(0xFF111827),
    success: Color(0xFF34D399),
    error: Color(0xFFF87171),
    inputFill: Color(0xFF1F2937),
    inputBorder: Color(0xFF4B5563),
    inputBorderFocused: Color(0xFF60A5FA),
  );
}
