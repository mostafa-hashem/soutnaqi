import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';

import 'package:soutnaqi/core/theme/magliss_context_colors.dart';
import 'package:soutnaqi/core/theme/magliss_typography.dart';
import 'package:soutnaqi/features/settings/cubit/settings_cubit.dart';

class UniversalMessageInputField extends StatelessWidget {
  const UniversalMessageInputField({
    super.key,
    required this.settingsCubit,
    required this.controller,
    required this.onSend,
    this.hint,
    this.enabled = true,
    this.isSending = false,
  });

  final SettingsCubit settingsCubit;
  final TextEditingController controller;
  final VoidCallback onSend;
  final String? hint;
  final bool enabled;
  final bool isSending;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled && !isSending,
                minLines: 1,
                maxLines: 4,
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
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Material(
              color: context.accentPrimary,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: enabled && !isSending ? onSend : null,
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: isSending
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: context.surfacePrimary,
                            ),
                          )
                        : HugeIcon(
                            icon: HugeIconsStrokeRounded.sent,
                            color: context.surfacePrimary,
                            size: 20,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
