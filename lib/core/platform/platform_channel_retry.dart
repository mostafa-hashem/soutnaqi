import 'package:flutter/services.dart';

import 'package:soutnaqi/core/logging/app_log.dart';

typedef PlatformChannelAction<T> = Future<T> Function();

Future<T> runWithPlatformChannelRetry<T>(
  PlatformChannelAction<T> action, {
  String? label,
  int maxAttempts = 4,
}) async {
  Object? lastError;

  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    try {
      return await action();
    } on MissingPluginException {
      rethrow;
    } on PlatformException catch (error) {
      final message = error.message ?? '';
      final isChannelNotReady = error.code == 'channel-error' ||
          message.contains('Unable to establish connection on channel');

      if (!isChannelNotReady) {
        rethrow;
      }

      lastError = error;
      appLog.e(
        '❌ Platform channel not ready${label == null ? '' : ' ($label)'} '
        '(attempt ${attempt + 1})',
        error: error,
      );
      await Future<void>.delayed(Duration(milliseconds: 120 * (attempt + 1)));
    }
  }

  if (lastError != null) {
    Error.throwWithStackTrace(lastError, StackTrace.current);
  }

  throw StateError('Platform channel unavailable');
}
