import 'package:flutter/material.dart';

import 'package:soutnaqi/features/settings/cubit/settings_cubit.dart';

const String kFontFamilyArabic = 'Cairo';
const String kFontFamilyLatin = 'Inter';

String fontFamilyFor(Locale locale) =>
    locale.languageCode == 'ar' ? kFontFamilyArabic : kFontFamilyLatin;

TextStyle _baseStyle({
  required SettingsCubit settingsCubit,
  required double size,
  required FontWeight weight,
  Color? color,
  double? height,
  double? letterSpacing,
}) {
  return TextStyle(
    fontFamily: fontFamilyFor(settingsCubit.state.locale),
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}

TextStyle font10W400({
  required SettingsCubit settingsCubit,
  Color? color,
}) =>
    _baseStyle(
      settingsCubit: settingsCubit,
      size: 10,
      weight: FontWeight.w400,
      color: color,
    );

TextStyle font12W400({
  required SettingsCubit settingsCubit,
  Color? color,
}) =>
    _baseStyle(
      settingsCubit: settingsCubit,
      size: 12,
      weight: FontWeight.w400,
      color: color,
    );

TextStyle font12W500({
  required SettingsCubit settingsCubit,
  Color? color,
}) =>
    _baseStyle(
      settingsCubit: settingsCubit,
      size: 12,
      weight: FontWeight.w500,
      color: color,
    );

TextStyle font14W400({
  required SettingsCubit settingsCubit,
  Color? color,
}) =>
    _baseStyle(
      settingsCubit: settingsCubit,
      size: 14,
      weight: FontWeight.w400,
      color: color,
    );

TextStyle font14W500({
  required SettingsCubit settingsCubit,
  Color? color,
}) =>
    _baseStyle(
      settingsCubit: settingsCubit,
      size: 14,
      weight: FontWeight.w500,
      color: color,
    );

TextStyle font14W600({
  required SettingsCubit settingsCubit,
  Color? color,
}) =>
    _baseStyle(
      settingsCubit: settingsCubit,
      size: 14,
      weight: FontWeight.w600,
      color: color,
    );

TextStyle font16W500({
  required SettingsCubit settingsCubit,
  Color? color,
}) =>
    _baseStyle(
      settingsCubit: settingsCubit,
      size: 16,
      weight: FontWeight.w500,
      color: color,
    );

TextStyle font16W600({
  required SettingsCubit settingsCubit,
  Color? color,
}) =>
    _baseStyle(
      settingsCubit: settingsCubit,
      size: 16,
      weight: FontWeight.w600,
      color: color,
    );

TextStyle font18W600({
  required SettingsCubit settingsCubit,
  Color? color,
}) =>
    _baseStyle(
      settingsCubit: settingsCubit,
      size: 18,
      weight: FontWeight.w600,
      color: color,
    );

TextStyle font20W700({
  required SettingsCubit settingsCubit,
  Color? color,
}) =>
    _baseStyle(
      settingsCubit: settingsCubit,
      size: 20,
      weight: FontWeight.w700,
      color: color,
    );

TextStyle font24W700({
  required SettingsCubit settingsCubit,
  Color? color,
}) =>
    _baseStyle(
      settingsCubit: settingsCubit,
      size: 24,
      weight: FontWeight.w700,
      color: color,
    );

TextStyle font32W700({
  required SettingsCubit settingsCubit,
  Color? color,
}) =>
    _baseStyle(
      settingsCubit: settingsCubit,
      size: 32,
      weight: FontWeight.w700,
      color: color,
    );
