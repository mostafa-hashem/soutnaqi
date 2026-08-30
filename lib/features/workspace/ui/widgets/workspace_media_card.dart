import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import 'package:soutnaqi/core/theme/magliss_context_colors.dart';
import 'package:soutnaqi/core/theme/magliss_typography.dart';
import 'package:soutnaqi/features/media/data/models/media_file.dart';
import 'package:soutnaqi/features/settings/cubit/settings_cubit.dart';
import 'package:soutnaqi/l10n/app_localizations.dart';

class WorkspaceMediaCard extends StatelessWidget {
  const WorkspaceMediaCard({
    super.key,
    required this.settingsCubit,
    required this.media,
    required this.formattedSize,
    required this.onClear,
    required this.isBusy,
  });

  final SettingsCubit settingsCubit;
  final MediaFile media;
  final String formattedSize;
  final VoidCallback onClear;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final icon = media.isAudio
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
                borderRadius: BorderRadius.circular(12),
              ),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: HugeIcon(
                    icon: icon,
                    color: context.accentPrimary,
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
                    media.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: font16W600(
                      settingsCubit: settingsCubit,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${media.isAudio ? l10n.mediaTypeAudio : l10n.mediaTypeVideo} · $formattedSize',
                    style: font12W400(
                      settingsCubit: settingsCubit,
                      color: context.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: isBusy ? null : onClear,
              icon: HugeIcon(
                icon: HugeIconsStrokeRounded.delete02,
                color: context.textMuted,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
