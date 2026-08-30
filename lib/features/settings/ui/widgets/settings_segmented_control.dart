import 'package:flutter/material.dart';

import 'package:soutnaqi/core/theme/app_radii.dart';
import 'package:soutnaqi/core/theme/magliss_context_colors.dart';
import 'package:soutnaqi/core/theme/magliss_typography.dart';
import 'package:soutnaqi/features/settings/cubit/settings_cubit.dart';

class SettingsSegmentedOption<T> {
  const SettingsSegmentedOption({
    required this.value,
    required this.label,
  });

  final T value;
  final String label;
}

class SettingsSegmentedControl<T> extends StatelessWidget {
  const SettingsSegmentedControl({
    super.key,
    required this.settingsCubit,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final SettingsCubit settingsCubit;
  final List<SettingsSegmentedOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.inputFill,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            for (final option in options)
              Expanded(
                child: _Segment(
                  settingsCubit: settingsCubit,
                  label: option.label,
                  selected: option.value == selected,
                  onTap: () => onSelected(option.value),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.settingsCubit,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final SettingsCubit settingsCubit;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? context.surfacePrimary : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      elevation: selected ? 0.4 : 0,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: font12W500(
              settingsCubit: settingsCubit,
              color: selected ? context.accentPrimary : context.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
