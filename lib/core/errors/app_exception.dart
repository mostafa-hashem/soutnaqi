enum AppExceptionType {
  generic,
  network,
  auth,
  validation,
  notFound,
  permission,
}

class AppException implements Exception {
  const AppException({
    required this.messageKey,
    this.type = AppExceptionType.generic,
    this.cause,
  });

  final String messageKey;
  final AppExceptionType type;
  final Object? cause;

  @override
  String toString() => 'AppException($type, $messageKey, cause: $cause)';
}
