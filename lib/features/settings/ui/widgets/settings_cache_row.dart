import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import 'package:soutnaqi/core/services/temp_storage_service.dart';
import 'package:soutnaqi/core/theme/magliss_context_colors.dart';
import 'package:soutnaqi/core/theme/magliss_typography.dart';
import 'package:soutnaqi/core/toast/app_toast.dart';
import 'package:soutnaqi/features/settings/cubit/settings_cubit.dart';
import 'package:soutnaqi/l10n/app_localizations.dart';

class SettingsCacheRow extends StatefulWidget {
  const SettingsCacheRow({super.key, required this.settingsCubit});

  final SettingsCubit settingsCubit;

  @override
  State<SettingsCacheRow> createState() => _SettingsCacheRowState();
}

class _SettingsCacheRowState extends State<SettingsCacheRow> {
  int _cacheSizeBytes = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
  }

  Future<void> _loadCacheSize() async {
    final size = await TempStorageService.instance.getTempFilesSizeBytes();
    if (mounted) {
      setState(() {
        _cacheSizeBytes = size;
        _isLoading = false;
      });
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _confirmAndClear() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: dialogContext.surfacePrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              HugeIcon(
                icon: HugeIconsStrokeRounded.delete02,
                color: dialogContext.danger,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.clearTempFiles,
                  style: font16W600(
                    settingsCubit: widget.settingsCubit,
                    color: dialogContext.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            l10n.clearTempFilesConfirm,
            style: font14W400(
              settingsCubit: widget.settingsCubit,
              color: dialogContext.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                l10n.cancelAction,
                style: font14W500(
                  settingsCubit: widget.settingsCubit,
                  color: dialogContext.textMuted,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: dialogContext.danger,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                l10n.confirmAction,
                style: font14W600(
                  settingsCubit: widget.settingsCubit,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    AppToast.showLoading(
      context,
      settingsCubit: widget.settingsCubit,
      message: l10n.clearTempFilesLoading,
    );

    try {
      await TempStorageService.instance.clearTempFiles();
      await _loadCacheSize();
      if (!mounted) return;
      AppToast.showSuccess(
        context,
        settingsCubit: widget.settingsCubit,
        message: l10n.clearTempFilesSuccess,
      );
    } catch (_) {
      if (!mounted) return;
      AppToast.showFailure(
        context,
        settingsCubit: widget.settingsCubit,
        message: l10n.genericError,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sizeFormatted = _isLoading ? '…' : _formatBytes(_cacheSizeBytes);

    return InkWell(
      onTap: _confirmAndClear,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            HugeIcon(
              icon: HugeIconsStrokeRounded.delete02,
              color: context.textPrimary,
              size: 20,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.clearTempFiles,
                    style: font14W600(
                      settingsCubit: widget.settingsCubit,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.tempStorageUsage(sizeFormatted),
                    style: font12W400(
                      settingsCubit: widget.settingsCubit,
                      color: context.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            HugeIcon(
              icon: HugeIconsStrokeRounded.arrowRight01,
              color: context.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
