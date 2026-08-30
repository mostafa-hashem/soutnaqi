import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:soutnaqi/core/errors/app_exception.dart';
import 'package:soutnaqi/core/logging/app_log.dart';
import 'package:soutnaqi/features/export/data/local_export_service.dart';

LocalExportService createPlatformLocalExportService() =>
    StubLocalExportService();

class StubLocalExportService implements LocalExportService {
  @override
  bool get isSupported => true;

  @override
  Future<bool> saveToDevice({
    required String? sourcePath,
    required List<int>? bytes,
    required String fileName,
  }) async {
    if (bytes == null) {
      throw const AppException(messageKey: 'exportFailed');
    }

    final extension = p.extension(fileName).replaceFirst('.', '');
    final savedPath = await FilePicker.platform.saveFile(
      fileName: fileName,
      bytes: Uint8List.fromList(bytes),
      type: FileType.custom,
      allowedExtensions: extension.isEmpty ? null : [extension],
    );

    if (savedPath == null) {
      appLog.d('🔍 Save cancelled by user');
      return false;
    }

    appLog.d('✅ Saved export via browser download');
    return true;
  }
}
