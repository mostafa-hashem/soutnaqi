import 'package:soutnaqi/core/config/app_env.dart';
import 'package:soutnaqi/l10n/app_localizations.dart';

String separationHintFor(AppLocalizations l10n) {
  if (AppEnv.isLocalSeparationConfigured) {
    return l10n.separationLocalHint;
  }
  if (AppEnv.isReplicateSeparationConfigured) {
    return l10n.separationCloudHint;
  }
  return l10n.separationAiHint;
}
