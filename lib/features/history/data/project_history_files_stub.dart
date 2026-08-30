import 'package:soutnaqi/core/errors/app_exception.dart';

Future<String> copyProjectFile({
  required String sourcePath,
  required String fileName,
}) {
  return Future<String>.error(
    const AppException(messageKey: 'processingWebUnsupported'),
    StackTrace.current,
  );
}

Future<void> deleteProjectFile(String path) {
  return Future<void>.value();
}
