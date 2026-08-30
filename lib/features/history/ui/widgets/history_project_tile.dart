import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import 'package:soutnaqi/core/theme/magliss_context_colors.dart';
import 'package:soutnaqi/core/theme/magliss_typography.dart';
import 'package:soutnaqi/features/history/data/models/project_record.dart';
import 'package:soutnaqi/features/history/ui/project_operation_l10n.dart';
import 'package:soutnaqi/features/settings/cubit/settings_cubit.dart';
import 'package:soutnaqi/l10n/app_localizations.dart';

class HistoryProjectTile extends StatelessWidget {
  const HistoryProjectTile({
    super.key,
    required this.settingsCubit,
    required this.project,
    required this.formattedDate,
    required this.onDelete,
    required this.onShare,
    this.isDeleting = false,
    this.isSharing = false,
  });

  final SettingsCubit settingsCubit;
  final ProjectRecord project;
  final String formattedDate;
  final VoidCallback onDelete;
  final VoidCallback onShare;
  final bool isDeleting;
  final bool isSharing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final icon = project.mediaType == ProjectMediaType.audio
        ? HugeIconsStrokeRounded.audioWave01
        : HugeIconsStrokeRounded.computerVideo;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.surfacePrimary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: context.accentPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: HugeIcon(
                    icon: icon,
                    color: context.accentPrimary,
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: font14W600(
                      settingsCubit: settingsCubit,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${project.mediaType == ProjectMediaType.audio ? l10n.mediaTypeAudio : l10n.mediaTypeVideo} · $formattedDate',
                    style: font12W400(
                      settingsCubit: settingsCubit,
                      color: context.textMuted,
                    ),
                  ),
                  if (project.operation != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      projectOperationLabel(project.operation, l10n),
                      style: font12W400(
                        settingsCubit: settingsCubit,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isDeleting || isSharing)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isDeleting ? context.error : context.accentPrimary,
                ),
              )
            else ...[
              IconButton(
                onPressed: onShare,
                icon: HugeIcon(
                  icon: HugeIconsStrokeRounded.share01,
                  color: context.textMuted,
                  size: 20,
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: HugeIcon(
                  icon: HugeIconsStrokeRounded.delete02,
                  color: context.textMuted,
                  size: 20,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
