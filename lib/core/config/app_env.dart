import 'package:flutter/foundation.dart';

class AppEnv {
  AppEnv._();

  /// Free option: Demucs server on your PC (see tools/local_demucs_server).
  static const separationServerUrl = String.fromEnvironment(
    'SEPARATION_SERVER_URL',
  );

  static bool get isLocalSeparationConfigured =>
      separationServerUrl.isNotEmpty;

  /// Paid cloud option (Replicate credits).
  static const replicateApiToken = String.fromEnvironment(
    'REPLICATE_API_TOKEN',
  );

  static bool get isReplicateSeparationConfigured =>
      replicateApiToken.isNotEmpty;

  /// Free, fully offline option: an on-device ONNX Demucs model, downloaded
  /// once and cached (see `features/separation/data/on_device`). Unlike the
  /// two flags above this isn't a dart-define secret — it just reflects
  /// whether the current platform is one the bundled ONNX Runtime plugin
  /// supports (every platform except web).
  static bool get isOnDeviceSeparationSupported => !kIsWeb;

  static bool get isSeparationConfigured =>
      isLocalSeparationConfigured ||
      isReplicateSeparationConfigured ||
      isOnDeviceSeparationSupported;
}
