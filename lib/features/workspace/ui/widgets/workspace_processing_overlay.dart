import 'package:flutter/material.dart';
import 'package:soutnaqi/core/theme/magliss_context_colors.dart';
import 'package:soutnaqi/core/theme/magliss_typography.dart';
import 'package:soutnaqi/core/widgets/app_loading_animation.dart';
import 'package:soutnaqi/features/settings/cubit/settings_cubit.dart';
import 'package:soutnaqi/features/workspace/cubit/workspace_state.dart';
import 'package:soutnaqi/features/workspace/ui/separation_progress_l10n.dart';
import 'package:soutnaqi/l10n/app_localizations.dart';

/// Full-screen, non-blocking progress sheet while separation or processing runs.
class WorkspaceProcessingOverlay extends StatelessWidget {
  const WorkspaceProcessingOverlay({
    required this.settingsCubit,
    required this.state,
    super.key,
  });

  final SettingsCubit settingsCubit;
  final WorkspaceState state;

  @override
  Widget build(BuildContext context) {
    if (!state.hasProcessingOverlay) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final title = separationProgressTitle(l10n, state);
    final subtitle = separationProgressSubtitle(l10n, state);
    final progress = state.processingProgress;

    return AbsorbPointer(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.45),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: context.accentPrimary.withValues(alpha: 0.25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          AppLoadingAnimation(
                            size: 28,
                            color: context.accentPrimary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              title,
                              style: font16W600(
                                settingsCubit: settingsCubit,
                                color: context.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          subtitle,
                          style: font14W400(
                            settingsCubit: settingsCubit,
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (progress != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progress.clamp(0, 1),
                            minHeight: 6,
                            backgroundColor:
                                context.accentPrimary.withValues(alpha: 0.12),
                            color: context.accentPrimary,
                          ),
                        )
                      else
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            minHeight: 6,
                            backgroundColor:
                                context.accentPrimary.withValues(alpha: 0.12),
                            color: context.accentPrimary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
