import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';

import 'package:soutnaqi/core/theme/magliss_context_colors.dart';
import 'package:soutnaqi/core/theme/magliss_typography.dart';
import 'package:soutnaqi/features/settings/cubit/settings_cubit.dart';

class MaglissTextField extends StatelessWidget {
  const MaglissTextField({
    super.key,
    required this.settingsCubit,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.errorText,
    this.obscureText = false,
    this.obscurable = false,
    this.showPasswordLabel,
    this.hidePasswordLabel,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.enabled = true,
    this.autofocus = false,
  });

  final SettingsCubit settingsCubit;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final String? errorText;
  final bool obscureText;
  final bool obscurable;
  final String? showPasswordLabel;
  final String? hidePasswordLabel;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final int maxLines;
  final bool enabled;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    if (obscurable) {
      return _MaglissObscurableTextField(
        settingsCubit: settingsCubit,
        controller: controller,
        focusNode: focusNode,
        label: label,
        hint: hint,
        errorText: errorText,
        showPasswordLabel: showPasswordLabel,
        hidePasswordLabel: hidePasswordLabel,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        enabled: enabled,
        autofocus: autofocus,
      );
    }

    return _MaglissTextFieldBody(
      settingsCubit: settingsCubit,
      controller: controller,
      focusNode: focusNode,
      label: label,
      hint: hint,
      errorText: errorText,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      maxLines: maxLines,
      enabled: enabled,
      autofocus: autofocus,
    );
  }
}

class _MaglissObscurableTextField extends StatefulWidget {
  const _MaglissObscurableTextField({
    required this.settingsCubit,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.errorText,
    this.showPasswordLabel,
    this.hidePasswordLabel,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.autofocus = false,
  });

  final SettingsCubit settingsCubit;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final String? errorText;
  final String? showPasswordLabel;
  final String? hidePasswordLabel;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final bool autofocus;

  @override
  State<_MaglissObscurableTextField> createState() =>
      _MaglissObscurableTextFieldState();
}

class _MaglissObscurableTextFieldState extends State<_MaglissObscurableTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final isHidden = _obscureText;
    final toggleLabel = isHidden
        ? widget.showPasswordLabel
        : widget.hidePasswordLabel;

    return _MaglissTextFieldBody(
      settingsCubit: widget.settingsCubit,
      controller: widget.controller,
      focusNode: widget.focusNode,
      label: widget.label,
      hint: widget.hint,
      errorText: widget.errorText,
      obscureText: _obscureText,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      suffix: Semantics(
        label: toggleLabel,
        button: true,
        child: IconButton(
          onPressed: widget.enabled
              ? () => setState(() => _obscureText = !_obscureText)
              : null,
          icon: HugeIcon(
            icon: isHidden
                ? HugeIconsStrokeRounded.view
                : HugeIconsStrokeRounded.viewOff,
            color: context.textMuted,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _MaglissTextFieldBody extends StatelessWidget {
  const _MaglissTextFieldBody({
    required this.settingsCubit,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.enabled = true,
    this.autofocus = false,
    this.suffix,
  });

  final SettingsCubit settingsCubit;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final int maxLines;
  final bool enabled;
  final bool autofocus;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: font14W500(
              settingsCubit: settingsCubit,
              color: context.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          maxLines: maxLines,
          enabled: enabled,
          autofocus: autofocus,
          style: font14W400(
            settingsCubit: settingsCubit,
            color: context.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: font14W400(
              settingsCubit: settingsCubit,
              color: context.textMuted,
            ),
            errorText: errorText,
            errorStyle: font12W400(
              settingsCubit: settingsCubit,
              color: context.error,
            ),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}
