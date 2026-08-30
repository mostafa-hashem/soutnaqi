import 'package:soutnaqi/core/errors/app_exception.dart';
import 'package:soutnaqi/l10n/app_localizations.dart';

String appExceptionMessage(AppException exception, AppLocalizations l10n) {
  return switch (exception.messageKey) {
    'networkError' => l10n.networkError,
    'mediaPickFailed' => l10n.mediaPickFailed,
    'processingFailed' => l10n.processingFailed,
    'processingWebUnsupported' => l10n.processingWebUnsupported,
    'processingAudioOnly' => l10n.processingAudioOnly,
    'processingVideoOnly' => l10n.processingVideoOnly,
    'waveformFailed' => l10n.waveformFailed,
    'exportFailed' => l10n.exportFailed,
    'saveFailed' => l10n.saveFailed,
    'saveToHistoryFailed' => l10n.saveToHistoryFailed,
    'historyLoadFailed' => l10n.historyLoadFailed,
    'historySaveFailed' => l10n.historySaveFailed,
    'historyDeleteFailed' => l10n.historyDeleteFailed,
    'separationNotConfigured' => l10n.separationNotConfigured,
    'separationServerUnreachable' => l10n.separationServerUnreachable,
    'separationFailed' => l10n.separationFailed,
    'separationInsufficientCredit' => l10n.separationInsufficientCredit,
    'separationTimeout' => l10n.separationTimeout,
    _ => l10n.genericError,
  };
}
