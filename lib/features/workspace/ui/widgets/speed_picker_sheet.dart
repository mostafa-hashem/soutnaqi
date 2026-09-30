import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import 'package:soutnaqi/core/theme/magliss_context_colors.dart';
import 'package:soutnaqi/core/theme/magliss_typography.dart';
import 'package:soutnaqi/features/settings/cubit/settings_cubit.dart';
import 'package:soutnaqi/l10n/app_localizations.dart';

const List<double> kAvailableSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

Future<double?> showSpeedPickerSheet(
  BuildContext context, {
  required SettingsCubit settingsCubit,
  required double currentSpeed,
  String? title,
}) {
  return showModalBottomSheet<double>(
    context: context,
    backgroundColor: context.surfacePrimary,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      final l10n = AppLocalizations.of(sheetContext);
      final displayTitle = title ?? l10n.speedPickerTitle;

      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: sheetContext.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    HugeIcon(
                      icon: HugeIconsStrokeRounded.dashboardSquare01,
                      color: sheetContext.accentPrimary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      displayTitle,
                      style: font16W600(
                        settingsCubit: settingsCubit,
                        color: sheetContext.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: kAvailableSpeeds.map((speed) {
                      final isSelected = (speed - currentSpeed).abs() < 0.01;
                      final label = speed == 1.0
                          ? '1.0x (${l10n.speedNormal})'
                          : '${speed}x';

                      return InkWell(
                        onTap: () => Navigator.of(sheetContext).pop(speed),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Text(
                                label,
                                style: font14W500(
                                  settingsCubit: settingsCubit,
                                  color: isSelected
                                      ? sheetContext.accentPrimary
                                      : sheetContext.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              if (isSelected)
                                HugeIcon(
                                  icon: HugeIconsStrokeRounded.tick02,
                                  color: sheetContext.accentPrimary,
                                  size: 18,
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
