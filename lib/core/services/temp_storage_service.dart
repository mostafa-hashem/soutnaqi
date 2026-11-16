import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:soutnaqi/core/logging/app_log.dart';

/// Manages SoutNaqi temporary media and separation work directories.
class TempStorageService {
  TempStorageService._();

  static final instance = TempStorageService._();
  static const _prefix = 'soutnaqi_';
  static const separationDirectoryPrefix = 'soutnaqi_separation_';

  final _active = <String>{};

  void protect(Directory directory) => _active.add(directory.path);

  void unprotect(Directory directory) => _active.remove(directory.path);

  Stream<FileSystemEntity> _managedEntries() async* {
    final directory = await getTemporaryDirectory();
    if (!await directory.exists()) return;
    await for (final entry in directory.list(followLinks: false)) {
      final name = p.basename(entry.path);
      if ((entry is File && name.startsWith(_prefix)) ||
          (entry is Directory && name.startsWith(separationDirectoryPrefix))) {
        yield entry;
      }
    }
  }

  Future<int> getTempFilesSizeBytes() async {
    var size = 0;
    try {
      await for (final entry in _managedEntries()) {
        if (entry is File) size += (await entry.stat()).size;
        if (entry is Directory) {
          await for (final file in entry.list(followLinks: false)) {
            if (file is File) size += (await file.stat()).size;
          }
        }
      }
    } catch (error) {
      appLog.w('Could not calculate temporary file size', error: error);
    }
    return size;
  }

  Future<void> clearTempFiles() => _clear();

  Future<void> cleanOldTempFiles({
    Duration maxAge = const Duration(hours: 24),
  }) => _clear(olderThan: DateTime.now().subtract(maxAge));

  Future<void> _clear({DateTime? olderThan}) async {
    try {
      await for (final entry in _managedEntries()) {
        try {
          if (olderThan != null &&
              !(await entry.stat()).modified.isBefore(olderThan)) {
            continue;
          }
          if (!_active.contains(entry.path)) {
            await entry.delete(recursive: entry is Directory);
          }
        } on FileSystemException catch (error) {
          appLog.w('Could not delete temporary media', error: error);
        }
      }
    } catch (error) {
      appLog.w('Could not list temporary media', error: error);
    }
  }
}
