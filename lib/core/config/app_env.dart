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

  static bool get isSeparationConfigured =>
      isLocalSeparationConfigured || isReplicateSeparationConfigured;
}
