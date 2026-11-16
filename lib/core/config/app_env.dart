import 'package:flutter/foundation.dart';

class AppEnv {
  AppEnv._();

  static const offlineOnly = bool.fromEnvironment('SOUTNAQI_OFFLINE_ONLY');

  /// Free option: Demucs server on your PC (see tools/local_demucs_server).
  static const separationServerUrl = String.fromEnvironment(
    'SEPARATION_SERVER_URL',
  );

  static bool get isLocalSeparationConfigured =>
      !offlineOnly && separationServerUrl.isNotEmpty;

  /// Paid cloud option (Replicate credits).
  static const replicateApiToken = String.fromEnvironment(
    'REPLICATE_API_TOKEN',
  );

  static bool get isReplicateSeparationConfigured =>
      !offlineOnly && replicateApiToken.isNotEmpty;

  /// Free, fully offline option: an on-device ONNX model (UVR-MDX-NET Voc FT),
  /// downloaded once and cached (see `features/separation/data/on_device`).
  /// Unlike the two flags above this isn't a dart-define secret — it just
  /// reflects whether the current platform is one the bundled ONNX Runtime
  /// plugin supports (every platform except web).
  static bool get isOnDeviceSeparationSupported => !kIsWeb;

  static bool get isSeparationConfigured =>
      isLocalSeparationConfigured ||
      isReplicateSeparationConfigured ||
      isOnDeviceSeparationSupported;
}
