import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:soutnaqi/core/logging/app_log.dart';

/// Manages background task execution and wake locks to prevent the OS from
/// suspending network downloads or long-running audio/video operations when
/// the app is in the background or the screen turns off.
class BackgroundTaskService {
  BackgroundTaskService._();

  static final BackgroundTaskService instance = BackgroundTaskService._();

  static const _channel = MethodChannel('com.soutnaqi.app/background');

  int _activeLocksCount = 0;

  /// Acquires a partial wake lock on Android to keep CPU active during long operations.
  Future<void> acquireWakeLock() async {
    if (kIsWeb || !Platform.isAndroid) return;
    _activeLocksCount++;
    if (_activeLocksCount == 1) {
      try {
        await _channel.invokeMethod<bool>('acquireWakeLock');
        appLog.d('⚡ Background WakeLock acquired');
      } catch (error) {
        appLog.w('⚠️ Failed to acquire WakeLock: $error');
      }
    }
  }

  /// Releases the wake lock when operations complete or cancel.
  Future<void> releaseWakeLock() async {
    if (kIsWeb || !Platform.isAndroid) return;
    if (_activeLocksCount > 0) {
      _activeLocksCount--;
    }
    if (_activeLocksCount == 0) {
      try {
        await _channel.invokeMethod<bool>('releaseWakeLock');
        appLog.d('⚡ Background WakeLock released');
      } catch (error) {
        appLog.w('⚠️ Failed to release WakeLock: $error');
      }
    }
  }

  /// Force-clears all wake locks (e.g. on full cancellation or error).
  Future<void> forceReleaseWakeLock() async {
    if (kIsWeb || !Platform.isAndroid) return;
    _activeLocksCount = 0;
    try {
      await _channel.invokeMethod<bool>('releaseWakeLock');
      appLog.d('⚡ Background WakeLock force released');
    } catch (error) {
      appLog.w('⚠️ Failed to release WakeLock: $error');
    }
  }
}
