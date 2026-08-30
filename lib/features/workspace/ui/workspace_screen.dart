import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soutnaqi/core/errors/app_exception.dart';
import 'package:soutnaqi/core/errors/app_exception_l10n.dart';
import 'package:soutnaqi/core/theme/magliss_context_colors.dart';
import 'package:soutnaqi/core/theme/magliss_typography.dart';
import 'package:soutnaqi/core/toast/app_toast.dart';
import 'package:soutnaqi/features/settings/cubit/settings_cubit.dart';
import 'package:soutnaqi/features/workspace/cubit/workspace_cubit.dart';
import 'package:soutnaqi/features/workspace/cubit/workspace_state.dart';
import 'package:soutnaqi/features/workspace/ui/widgets/workspace_empty_state.dart';
import 'package:soutnaqi/features/workspace/ui/widgets/workspace_loaded_view.dart';
import 'package:soutnaqi/l10n/app_localizations.dart';

class WorkspaceScreen extends StatelessWidget {
  const WorkspaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsCubit = context.read<SettingsCubit>();

    return ColoredBox(
      color: context.webBackground,
      child: BlocBuilder<WorkspaceCubit, WorkspaceState>(
        builder: (context, state) {
          final content = !state.hasMedia
              ? WorkspaceEmptyState(
                  settingsCubit: settingsCubit,
                  isBusy: state.isBusy,
                  showDropHint: kIsWeb,
                  onPickAudio: () => _pickAudio(context),
                  onPickVideo: () => _pickVideo(context),
                )
              : WorkspaceLoadedView(
                  settingsCubit: settingsCubit,
                  state: state,
                );

          if (!kIsWeb) return content;

          return _WebDropZone(
            settingsCubit: settingsCubit,
            child: content,
          );
        },
      ),
    );
  }

  Future<void> _pickAudio(BuildContext context) async {
    await _runWithToast(
      context,
      loadingMessage: AppLocalizations.of(context).pickAudioLoading,
      successMessage: AppLocalizations.of(context).pickMediaSuccess,
      action: context.read<WorkspaceCubit>().pickAudio,
    );
  }

  Future<void> _pickVideo(BuildContext context) async {
    await _runWithToast(
      context,
      loadingMessage: AppLocalizations.of(context).pickVideoLoading,
      successMessage: AppLocalizations.of(context).pickMediaSuccess,
      action: context.read<WorkspaceCubit>().pickVideo,
    );
  }

  Future<void> _runWithToast(
    BuildContext context, {
    required String loadingMessage,
    required String successMessage,
    required Future<void> Function() action,
  }) async {
    final settingsCubit = context.read<SettingsCubit>();
    final l10n = AppLocalizations.of(context);

    AppToast.showLoading(
      context,
      settingsCubit: settingsCubit,
      message: loadingMessage,
    );

    try {
      await action();
      if (!context.mounted) return;
      final hasMedia = context.read<WorkspaceCubit>().state.hasMedia;
      if (hasMedia) {
        AppToast.showSuccess(
          context,
          settingsCubit: settingsCubit,
          message: successMessage,
        );
      } else {
        AppToast.dismiss();
      }
    } on AppException catch (error) {
      if (!context.mounted) return;
      AppToast.showFailure(
        context,
        settingsCubit: settingsCubit,
        message: appExceptionMessage(error, l10n),
      );
    }
  }
}

class _WebDropZone extends StatefulWidget {
  const _WebDropZone({
    required this.settingsCubit,
    required this.child,
  });

  final SettingsCubit settingsCubit;
  final Widget child;

  @override
  State<_WebDropZone> createState() => _WebDropZoneState();
}

class _WebDropZoneState extends State<_WebDropZone> {
  bool _isDragging = false;

  Future<void> _handleDrop(BuildContext context, XFile file) async {
    final l10n = AppLocalizations.of(context);

    AppToast.showLoading(
      context,
      settingsCubit: widget.settingsCubit,
      message: l10n.dropLoading,
    );

    try {
      await context.read<WorkspaceCubit>().importDroppedFile(file);
      if (!context.mounted) return;
      final hasMedia = context.read<WorkspaceCubit>().state.hasMedia;
      if (hasMedia) {
        AppToast.showSuccess(
          context,
          settingsCubit: widget.settingsCubit,
          message: l10n.pickMediaSuccess,
        );
      } else {
        AppToast.dismiss();
      }
    } on AppException catch (error) {
      if (!context.mounted) return;
      AppToast.showFailure(
        context,
        settingsCubit: widget.settingsCubit,
        message: appExceptionMessage(error, l10n),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (details) async {
        setState(() => _isDragging = false);
        if (details.files.isEmpty) return;
        await _handleDrop(context, details.files.first);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          if (_isDragging)
            DecoratedBox(
              decoration: BoxDecoration(
                color: context.accentPrimary.withValues(alpha: 0.08),
                border: Border.all(
                  color: context.accentPrimary,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  l10n.dropHint,
                  textAlign: TextAlign.center,
                  style: font16W600(
                    settingsCubit: widget.settingsCubit,
                    color: context.accentPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
