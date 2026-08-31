import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';

import 'package:soutnaqi/core/errors/app_exception.dart';
import 'package:soutnaqi/core/errors/app_exception_l10n.dart';
import 'package:soutnaqi/core/theme/magliss_context_colors.dart';
import 'package:soutnaqi/core/theme/magliss_typography.dart';
import 'package:soutnaqi/features/separation/cubit/on_device_model_cubit.dart';
import 'package:soutnaqi/features/separation/cubit/on_device_model_state.dart';
import 'package:soutnaqi/features/settings/cubit/settings_cubit.dart';
import 'package:soutnaqi/l10n/app_localizations.dart';

/// Lets the user see whether the on-device separation model is cached,
/// download it ahead of time, or delete it to free up space.
class SettingsOnDeviceModelRow extends StatefulWidget {
  const SettingsOnDeviceModelRow({required this.settingsCubit, super.key});

  final SettingsCubit settingsCubit;

  @override
  State<SettingsOnDeviceModelRow> createState() =>
      _SettingsOnDeviceModelRowState();
}

class _SettingsOnDeviceModelRowState extends State<SettingsOnDeviceModelRow> {
  @override
  void initState() {
    super.initState();
    unawaited(context.read<OnDeviceModelCubit>().refresh());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: BlocBuilder<OnDeviceModelCubit, OnDeviceModelState>(
        builder: (context, state) {
          return Row(
            children: [
              HugeIcon(
                icon: HugeIconsStrokeRounded.cloudDownload,
                color: context.accentPrimary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.separationModelSection,
                      style: font14W600(
                        settingsCubit: widget.settingsCubit,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _statusText(l10n, state),
                      style: font12W400(
                        settingsCubit: widget.settingsCubit,
                        color: state.status == OnDeviceModelStatus.error
                            ? context.error
                            : context.textMuted,
                      ),
                    ),
                    if (state.status == OnDeviceModelStatus.downloading) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: state.downloadProgress,
                          minHeight: 4,
                          backgroundColor: context.borderSubtle,
                          color: context.accentPrimary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _TrailingAction(settingsCubit: widget.settingsCubit, state: state),
            ],
          );
        },
      ),
    );
  }

  String _statusText(AppLocalizations l10n, OnDeviceModelState state) {
    return switch (state.status) {
      OnDeviceModelStatus.checking => l10n.toastLoading,
      OnDeviceModelStatus.notDownloaded => l10n.separationModelNotDownloaded,
      OnDeviceModelStatus.downloading => l10n.separationModelDownloading(
          (state.downloadProgress * 100).round(),
        ),
      OnDeviceModelStatus.ready => l10n.separationModelReady(
          _formatSize(state.cachedSizeBytes),
        ),
      OnDeviceModelStatus.error => state.errorMessageKey != null
          ? appExceptionMessage(
              AppException(messageKey: state.errorMessageKey!),
              l10n,
            )
          : l10n.genericError,
    };
  }

  String _formatSize(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(0)} MB';
  }
}

class _TrailingAction extends StatelessWidget {
  const _TrailingAction({required this.settingsCubit, required this.state});

  final SettingsCubit settingsCubit;
  final OnDeviceModelState state;

  @override
  Widget build(BuildContext context) {
    if (state.status == OnDeviceModelStatus.checking ||
        state.status == OnDeviceModelStatus.downloading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (state.status == OnDeviceModelStatus.ready) {
      return IconButton(
        onPressed: () => context.read<OnDeviceModelCubit>().delete(),
        icon: HugeIcon(
          icon: HugeIconsStrokeRounded.delete02,
          color: context.textMuted,
          size: 20,
        ),
      );
    }

    final l10n = AppLocalizations.of(context);
    return TextButton(
      onPressed: () => context.read<OnDeviceModelCubit>().download(),
      child: Text(
        l10n.separationModelDownloadAction,
        style: font14W600(
          settingsCubit: settingsCubit,
          color: context.accentPrimary,
        ),
      ),
    );
  }
}
