import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:soutnaqi/core/logging/app_log.dart';

/// Manages SoutNaqi temporary processing files (audio/video exports, waveforms, FFmpeg chunks)
/// to prevent storage bloat over time.
class TempStorageService {
  TempStorageService._();

  static final TempStorageService instance = TempStorageService._();

  static const String _prefix = 'soutnaqi_';

  /// Returns the total size in bytes of all SoutNaqi temporary files.
  Future<int> getTempFilesSizeBytes() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (!tempDir.existsSync()) return 0;

      int totalBytes = 0;
      final entities = tempDir.listSync(followLinks: false);
      for (final entity in entities) {
        if (entity is File) {
          final fileName = entity.uri.pathSegments.last;
          if (fileName.startsWith(_prefix)) {
            totalBytes += entity.lengthSync();
          }
        }
      }
      return totalBytes;
    } catch (error) {
      appLog.w('⚠️ Failed to calculate temp files size: $error');
      return 0;
    }
  }

  /// Deletes all SoutNaqi temporary files.
  Future<void> clearTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (!tempDir.existsSync()) return;

      final entities = tempDir.listSync(followLinks: false);
      int deletedCount = 0;
      for (final entity in entities) {
        if (entity is File) {
          final fileName = entity.uri.pathSegments.last;
          if (fileName.startsWith(_prefix)) {
            try {
              entity.deleteSync();
              deletedCount++;
            } catch (_) {}
          }
        }
      }
      appLog.d('🧹 Cleared $deletedCount SoutNaqi temp files');
    } catch (error) {
      appLog.e('❌ Failed to clear temp files', error: error);
    }
  }

  /// Deletes SoutNaqi temporary files older than [maxAge] (default: 24 hours).
  /// Safe to call on app startup to reclaim unused storage.
  Future<void> cleanOldTempFiles({
    Duration maxAge = const Duration(hours: 24),
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (!tempDir.existsSync()) return;

      final threshold = DateTime.now().subtract(maxAge);
      final entities = tempDir.listSync(followLinks: false);
      int deletedCount = 0;

      for (final entity in entities) {
        if (entity is File) {
          final fileName = entity.uri.pathSegments.last;
          if (fileName.startsWith(_prefix)) {
            try {
              final stat = entity.statSync();
              if (stat.modified.isBefore(threshold)) {
                entity.deleteSync();
                deletedCount++;
              }
            } catch (_) {}
          }
        }
      }

      if (deletedCount > 0) {
        appLog.d('🧹 Auto-cleaned $deletedCount old SoutNaqi temp files (> ${maxAge.inHours}h)');
      }
    } catch (error) {
      appLog.w('⚠️ Auto-cleaning old temp files skipped: $error');
    }
  }
}
