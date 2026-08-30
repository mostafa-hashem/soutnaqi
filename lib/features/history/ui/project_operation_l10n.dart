import 'package:soutnaqi/l10n/app_localizations.dart';

String projectOperationLabel(String? operationKey, AppLocalizations l10n) {
  if (operationKey == null || operationKey.isEmpty) {
    return '';
  }

  return switch (operationKey) {
    'normalize' => l10n.operationNormalize,
    'noise_reduction' => l10n.operationNoiseReduction,
    'trim' => l10n.operationTrim,
    'extract_audio' => l10n.operationExtractAudio,
    'compress' => l10n.operationCompressVideo,
    'isolate_vocals' => l10n.operationIsolateVocals,
    'isolate_music' => l10n.operationIsolateMusic,
    _ => operationKey,
  };
}
