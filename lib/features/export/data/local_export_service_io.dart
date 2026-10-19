import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:soutnaqi/core/errors/app_exception.dart';
import 'package:soutnaqi/core/logging/app_log.dart';
import 'package:soutnaqi/features/export/data/local_export_service.dart';

LocalExportService createPlatformLocalExportService() =>
    IoLocalExportService();

class IoLocalExportService implements LocalExportService {
  static const _storageChannel = MethodChannel('com.soutnaqi.app/storage');

  @override
  bool get isSupported => true;

  @override
  Future<LocalExportResult> saveToDevice({
    required String? sourcePath,
    required List<int>? bytes,
    required String fileName,
    bool? isVideo,
  }) async {
    if (sourcePath == null && bytes == null) {
      throw const AppException(messageKey: 'exportFailed');
    }

    final effectiveIsVideo = isVideo ?? _detectIsVideo(fileName);

    File? tempFile;
    String? effectiveSourcePath = sourcePath;

    if (effectiveSourcePath == null || !File(effectiveSourcePath).existsSync()) {
      if (bytes != null) {
        final tempDir = Directory.systemTemp;
        tempFile = File(p.join(tempDir.path, fileName));
        await tempFile.writeAsBytes(bytes);
        effectiveSourcePath = tempFile.path;
      }
    }

    try {
      if (Platform.isAndroid && effectiveSourcePath != null) {
        final nativeResult = await _saveViaNativeAndroid(
          sourcePath: effectiveSourcePath,
          fileName: fileName,
          isVideo: effectiveIsVideo,
        );
        if (nativeResult != null && nativeResult.isSuccess) {
          appLog.d('✅ Saved export to DCIM/SoutNaqi: ${nativeResult.displayPath}');
          return nativeResult;
        }
      }

      final fileBytes = bytes ?? (effectiveSourcePath != null ? await File(effectiveSourcePath).readAsBytes() : null);
      if (fileBytes == null) {
        return LocalExportResult.failure;
      }

      return await _saveWithPicker(fileName: fileName, bytes: fileBytes);
    } finally {
      if (tempFile != null && tempFile.existsSync()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
    }
  }

  Future<LocalExportResult?> _saveViaNativeAndroid({
    required String sourcePath,
    required String fileName,
    required bool isVideo,
  }) async {
    try {
      final result = await _storageChannel.invokeMapMethod<String, dynamic>(
        'saveMedia',
        {
          'sourcePath': sourcePath,
          'fileName': fileName,
          'isVideo': isVideo,
        },
      );

      if (result != null && result['success'] == true) {
        return LocalExportResult(
          isSuccess: true,
          displayPath: result['displayPath'] as String?,
          fullPath: result['fullPath'] as String?,
        );
      } else if (result != null) {
        appLog.w('⚠️ Android native save error: ${result['error']}');
      }
    } catch (error) {
      appLog.w('⚠️ Android native save channel failed: $error');
    }
    return null;
  }

  Future<LocalExportResult> _saveWithPicker({
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
      return LocalExportResult.failure;
    }

    appLog.d('✅ Saved export via picker: $savedPath');
    return LocalExportResult(
      isSuccess: true,
      displayPath: p.basename(savedPath),
      fullPath: savedPath,
    );
  }

  bool _detectIsVideo(String fileName) {
    final ext = p.extension(fileName).toLowerCase();
    return ext == '.mp4' ||
        ext == '.mov' ||
        ext == '.mkv' ||
        ext == '.avi' ||
        ext == '.webm' ||
        ext == '.3gp';
  }
}
