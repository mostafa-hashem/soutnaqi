import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:soutnaqi/core/errors/app_exception.dart';
import 'package:soutnaqi/core/logging/app_log.dart';
import 'package:soutnaqi/features/export/data/local_export_service.dart';

LocalExportService createPlatformLocalExportService() =>
    IoLocalExportService();

class IoLocalExportService implements LocalExportService {
  @override
  bool get isSupported => true;

  @override
  Future<bool> saveToDevice({
    required String? sourcePath,
    required List<int>? bytes,
    required String fileName,
  }) async {
    if (sourcePath == null && bytes == null) {
      throw const AppException(messageKey: 'exportFailed');
    }

    final fileBytes =
        bytes ?? await File(sourcePath!).readAsBytes();

    if (Platform.isAndroid) {
      final directPath = await _trySaveToPublicDownloads(
        sourcePath: sourcePath,
        fileName: fileName,
      );
      if (directPath != null) {
        appLog.d('✅ Saved export to Downloads: $directPath');
        return true;
      }
    }

    return _saveWithPicker(fileName: fileName, bytes: fileBytes);
  }

  Future<String?> _trySaveToPublicDownloads({
    required String? sourcePath,
    required String fileName,
  }) async {
    if (sourcePath == null) return null;

    const roots = [
      '/storage/emulated/0/Download/SoutNaqi',
      '/sdcard/Download/SoutNaqi',
    ];

    for (final root in roots) {
      try {
        final directory = Directory(root);
        await directory.create(recursive: true);
        final destination = File('${directory.path}/$fileName');
        await File(sourcePath).copy(destination.path);
        return destination.path;
      } catch (error) {
        appLog.d('⚡ Downloads save attempt failed ($root): $error');
      }
    }

    return null;
  }

  Future<bool> _saveWithPicker({
    required String fileName,
    required List<int> bytes,
  }) async {
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

    appLog.d('✅ Saved export via picker: $savedPath');
    return true;
  }
}
