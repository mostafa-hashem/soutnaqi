import 'package:logger/logger.dart';

final AppLog appLog = AppLog._();

class AppLog {
  AppLog._();

  final Logger _logger = Logger(
    printer: PrettyPrinter(methodCount: 0, errorMethodCount: 5, lineLength: 80),
  );

  void d(String message) => _logger.d(message);

  void w(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) =>
      _logger.w(message, error: error, stackTrace: stackTrace);

  void e(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
}
