import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:soutnaqi/core/errors/app_exception.dart';
import 'package:soutnaqi/core/errors/app_exception_l10n.dart';
import 'package:soutnaqi/core/layout/magliss_safe_insets.dart';
import 'package:soutnaqi/core/theme/magliss_context_colors.dart';
import 'package:soutnaqi/core/theme/magliss_typography.dart';
import 'package:soutnaqi/core/toast/app_toast.dart';
import 'package:soutnaqi/features/history/cubit/history_cubit.dart';
import 'package:soutnaqi/features/history/cubit/history_state.dart';
import 'package:soutnaqi/features/history/data/models/project_record.dart';
import 'package:soutnaqi/features/history/ui/widgets/history_project_tile.dart';
import 'package:soutnaqi/features/settings/cubit/settings_cubit.dart';
import 'package:soutnaqi/l10n/app_localizations.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String? _sharingProjectId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHistory());
  }

  Future<void> _loadHistory() async {
    final settingsCubit = context.read<SettingsCubit>();
    final l10n = AppLocalizations.of(context);

    try {
      await context.read<HistoryCubit>().loadProjects();
    } on AppException catch (error) {
      if (!mounted) return;
      AppToast.showFailure(
        context,
        settingsCubit: settingsCubit,
        message: appExceptionMessage(error, l10n),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsCubit = context.read<SettingsCubit>();
    final l10n = AppLocalizations.of(context);

    return ColoredBox(
      color: context.webBackground,
      child: BlocBuilder<HistoryCubit, HistoryState>(
        builder: (context, state) {
          if (state.isLoading && state.projects.isEmpty) {
            return _LoadingList(settingsCubit: settingsCubit);
          }

          if (state.projects.isEmpty) {
            return _EmptyHistory(
              settingsCubit: settingsCubit,
              onRefresh: _loadHistory,
            );
          }

          return RefreshIndicator(
            onRefresh: _loadHistory,
            color: context.accentPrimary,
            child: ListView.separated(
              padding: context.maglissShellScrollPadding(),
              itemCount: state.projects.length,
              separatorBuilder: (_, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final project = state.projects[index];
                return HistoryProjectTile(
                  settingsCubit: settingsCubit,
                  project: project,
                  formattedDate: _formatDate(project.createdAt, l10n),
                  isDeleting: state.deletingProjectId == project.id,
                  isSharing: _sharingProjectId == project.id,
                  onShare: () => _shareProject(context, project),
                  onDelete: () => _deleteProject(context, project.id),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _shareProject(BuildContext context, ProjectRecord project) async {
    final settingsCubit = context.read<SettingsCubit>();
    final l10n = AppLocalizations.of(context);

    setState(() => _sharingProjectId = project.id);
    AppToast.showLoading(
      context,
      settingsCubit: settingsCubit,
      message: l10n.historyShareLoading,
    );

    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(project.filePath)],
        ),
      );
      if (!mounted) return;
      setState(() => _sharingProjectId = null);
      if (!context.mounted) return;
      AppToast.showSuccess(
        context,
        settingsCubit: settingsCubit,
        message: l10n.historyShareSuccess,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _sharingProjectId = null);
      if (!context.mounted) return;
      AppToast.showFailure(
        context,
        settingsCubit: settingsCubit,
        message: l10n.genericError,
      );
    }
  }

  Future<void> _deleteProject(BuildContext context, String projectId) async {
    final settingsCubit = context.read<SettingsCubit>();
    final l10n = AppLocalizations.of(context);

    AppToast.showLoading(
      context,
      settingsCubit: settingsCubit,
      message: l10n.historyDeleteLoading,
    );

    try {
      await context.read<HistoryCubit>().deleteProject(projectId);
      if (!context.mounted) return;
      AppToast.showSuccess(
        context,
        settingsCubit: settingsCubit,
        message: l10n.historyDeleteSuccess,
      );
    } on AppException catch (error) {
      if (!context.mounted) return;
      AppToast.showFailure(
        context,
        settingsCubit: settingsCubit,
        message: appExceptionMessage(error, l10n),
      );
    }
  }

  String _formatDate(DateTime date, AppLocalizations l10n) {
    final locale = l10n.localeName;
    return DateFormat.yMMMd(locale).add_jm().format(date.toLocal());
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList({required this.settingsCubit});

  final SettingsCubit settingsCubit;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: ListView.separated(
        padding: context.maglissShellScrollPadding(),
        itemCount: 4,
        separatorBuilder: (_, index) => const SizedBox(height: 12),
        itemBuilder: (_, index) => DecoratedBox(
          decoration: BoxDecoration(
            color: context.surfacePrimary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const SizedBox(height: 72),
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({
    required this.settingsCubit,
    required this.onRefresh,
  });

  final SettingsCubit settingsCubit;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: context.accentPrimary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: context.maglissShellScrollPadding(),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
          HugeIcon(
            icon: HugeIconsStrokeRounded.folderOpen,
            color: context.textMuted,
            size: 56,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.historyEmptyTitle,
            textAlign: TextAlign.center,
            style: font18W600(
              settingsCubit: settingsCubit,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.historyEmptySubtitle,
            textAlign: TextAlign.center,
            style: font14W400(
              settingsCubit: settingsCubit,
              color: context.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
