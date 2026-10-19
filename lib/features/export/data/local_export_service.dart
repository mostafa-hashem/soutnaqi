class LocalExportResult {
  const LocalExportResult({
    required this.isSuccess,
    this.displayPath,
    this.fullPath,
  });

  final bool isSuccess;
  final String? displayPath;
  final String? fullPath;

  static const failure = LocalExportResult(isSuccess: false);
}

abstract class LocalExportService {
  bool get isSupported;

  /// Saves [sourcePath] or [bytes] under [fileName].
  ///
  /// Returns [LocalExportResult] containing success state and destination paths.
  Future<LocalExportResult> saveToDevice({
    required String? sourcePath,
    required List<int>? bytes,
    required String fileName,
    bool? isVideo,
  });
}
