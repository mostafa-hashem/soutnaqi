import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:soutnaqi/core/errors/app_exception.dart';
import 'package:soutnaqi/core/logging/app_log.dart';
import 'package:soutnaqi/core/platform/platform_channel_retry.dart';
import 'package:uuid/uuid.dart';

Future<String> copyProjectFile({
  required String sourcePath,
  required String fileName,
}) async {
  final source = File(sourcePath);
  if (!source.existsSync()) {
    throw const AppException(messageKey: 'exportFailed');
  }

  final documents = await runWithPlatformChannelRetry(
    getApplicationDocumentsDirectory,
    label: 'path_provider',
  );
  final directory = Directory(p.join(documents.path, 'projects'));
  await directory.create(recursive: true);

  final storedName = '${const Uuid().v4()}_$fileName';
  final destination = p.join(directory.path, storedName);
  await source.copy(destination);
  appLog.d('✅ Copied project file to $destination');
  return destination;
}

Future<void> deleteProjectFile(String path) async {
  final file = File(path);
  if (!file.existsSync()) return;
  await file.delete();
  appLog.d('✅ Deleted project file $path');
}
