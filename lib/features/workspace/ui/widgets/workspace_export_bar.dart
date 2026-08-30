import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import 'package:soutnaqi/core/theme/magliss_context_colors.dart';
import 'package:soutnaqi/core/theme/magliss_typography.dart';
import 'package:soutnaqi/features/settings/cubit/settings_cubit.dart';
import 'package:soutnaqi/features/workspace/cubit/workspace_state.dart';
import 'package:soutnaqi/l10n/app_localizations.dart';

class WorkspaceExportBar extends StatelessWidget {
  const WorkspaceExportBar({
    super.key,
    required this.settingsCubit,
    required this.state,
    required this.onShare,
    required this.onSave,
    required this.onSaveToHistory,
  });

  final SettingsCubit settingsCubit;
  final WorkspaceState state;
  final VoidCallback onShare;
  final VoidCallback onSave;
  final VoidCallback onSaveToHistory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.surfacePrimary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.exportTitle,
              style: font16W600(
                settingsCubit: settingsCubit,
                color: context.textPrimary,
              ),
            ),
            if (state.historyPath != null) ...[
              const SizedBox(height: 8),
              Text(
                l10n.saveToHistoryCompleteHint,
                style: font12W400(
                  settingsCubit: settingsCubit,
                  color: context.success,
                ),
              ),
            ],
            const SizedBox(height: 12),
            _ActionButton(
              settingsCubit: settingsCubit,
              label: l10n.saveExport,
              icon: HugeIconsStrokeRounded.download01,
              isLoading: state.isSaving,
              onPressed: state.isBusy ? null : onSave,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    settingsCubit: settingsCubit,
                    label: l10n.shareExport,
                    icon: HugeIconsStrokeRounded.share01,
                    isLoading: state.isSharing,
                    onPressed: state.isBusy ? null : onShare,
                    isSecondary: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    settingsCubit: settingsCubit,
                    label: l10n.saveToHistory,
                    icon: HugeIconsStrokeRounded.timeSchedule,
                    isLoading: state.isSavingToHistory,
                    onPressed: state.isBusy ? null : onSaveToHistory,
                    isSecondary: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.settingsCubit,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
  });

  final SettingsCubit settingsCubit;
  final String label;
  final List<List<dynamic>> icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;

  @override
  Widget build(BuildContext context) {
    final background = isSecondary ? context.inputFill : context.accentPrimary;
    final foreground = isSecondary ? context.textPrimary : context.onAccent;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 44,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: foreground,
                  ),
                )
              else
                HugeIcon(icon: icon, color: foreground, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: font14W500(
                    settingsCubit: settingsCubit,
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
