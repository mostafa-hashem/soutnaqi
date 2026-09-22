import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';

import 'package:soutnaqi/core/layout/magliss_safe_insets.dart';
import 'package:soutnaqi/core/theme/magliss_context_colors.dart';
import 'package:soutnaqi/core/theme/magliss_typography.dart';
import 'package:soutnaqi/core/widgets/app_loading_animation.dart';
import 'package:soutnaqi/features/settings/cubit/settings_cubit.dart';
import 'package:soutnaqi/l10n/app_localizations.dart';

enum ToastPhase { loading, success, failure }

class AppToast {
  AppToast._();

  static OverlayEntry? _currentEntry;

  static void dismiss() {
    _currentEntry?.remove();
    _currentEntry = null;
  }

  static void showLoading(
    BuildContext context, {
    required SettingsCubit settingsCubit,
    String? message,
  }) {
    _show(
      context,
      settingsCubit: settingsCubit,
      phase: ToastPhase.loading,
      message: message ?? AppLocalizations.of(context).toastLoading,
    );
  }

  static void showFailure(
    BuildContext context, {
    required SettingsCubit settingsCubit,
    String? message,
    Duration? duration,
  }) {
    dismiss();
    final resolved = message ?? AppLocalizations.of(context).toastFailure;
    _show(
      context,
      settingsCubit: settingsCubit,
      phase: ToastPhase.failure,
      message: resolved,
      autoDismiss: true,
      duration: duration ?? _readableDuration(resolved),
    );
  }

  static void showSuccess(
    BuildContext context, {
    required SettingsCubit settingsCubit,
    String? message,
    Duration? duration,
  }) {
    dismiss();
    final resolved = message ?? AppLocalizations.of(context).toastSuccess;
    _show(
      context,
      settingsCubit: settingsCubit,
      phase: ToastPhase.success,
      message: resolved,
      autoDismiss: true,
      duration: duration ?? _readableDuration(resolved),
    );
  }

  /// Keeps longer guidance messages on screen longer (min 3s, max 8s).
  static Duration _readableDuration(String message) {
    final ms = (2800 + message.length * 45).clamp(3000, 8000);
    return Duration(milliseconds: ms);
  }

  static void _show(
    BuildContext context, {
    required SettingsCubit settingsCubit,
    required ToastPhase phase,
    required String message,
    bool autoDismiss = false,
    Duration? duration,
  }) {
    dismiss();

    final overlay = Overlay.of(context);
    _currentEntry = OverlayEntry(
      builder: (overlayContext) {
        final colors = _phaseColors(overlayContext, phase);
        final bottom = overlayContext.maglissToastBottomOffset();
        return Positioned(
          bottom: bottom,
          left: 24,
          right: 24,
          child: Material(
            color: Colors.transparent,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: overlayContext.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: phase == ToastPhase.loading
                              ? AppLoadingAnimation(
                                  size: 28,
                                  color: colors.icon,
                                )
                              : HugeIcon(
                                  icon: phase == ToastPhase.success
                                      ? HugeIconsStrokeRounded.tick02
                                      : HugeIconsStrokeRounded.cancel01,
                                  color: colors.icon,
                                  size: 20,
                                ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            message,
                            textAlign: TextAlign.start,
                            style: font14W500(
                              settingsCubit: settingsCubit,
                              color: overlayContext.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_currentEntry!);

    if (autoDismiss) {
      final entry = _currentEntry;
      Future<void>.delayed(
        duration ?? const Duration(seconds: 3),
        () {
          if (_currentEntry == entry) dismiss();
        },
      );
    }
  }

  static _ToastColors _phaseColors(BuildContext context, ToastPhase phase) {
    return switch (phase) {
      ToastPhase.loading => _ToastColors(
          icon: context.accentPrimary,
          border: context.accentPrimary.withValues(alpha: 0.3),
        ),
      ToastPhase.success => _ToastColors(
          icon: context.success,
          border: context.success.withValues(alpha: 0.3),
        ),
      ToastPhase.failure => _ToastColors(
          icon: context.error,
          border: context.error.withValues(alpha: 0.3),
        ),
    };
  }
}

class _ToastColors {
  const _ToastColors({required this.icon, required this.border});

  final Color icon;
  final Color border;
}
