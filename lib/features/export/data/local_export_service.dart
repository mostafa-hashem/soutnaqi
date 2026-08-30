abstract class LocalExportService {
  bool get isSupported;

  /// Saves [sourcePath] or [bytes] under [fileName].
  ///
  /// Returns `true` when saved, `false` when the user cancels the picker.
  Future<bool> saveToDevice({
    required String? sourcePath,
    required List<int>? bytes,
    required String fileName,
  });
}
