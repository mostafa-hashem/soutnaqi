import 'package:flutter/widgets.dart';

import 'package:soutnaqi/core/logging/app_log.dart';
import 'package:soutnaqi/core/storage/preferences_store.dart';

/// Warms platform channels after the first frame is drawn.
class AppPlatform {
  AppPlatform._();

  static bool _ready = false;
  static Future<void>? _initializing;

  static Future<void> warmUpAfterFirstFrame() {
    return _initializing ??= _initialize();
  }

  static Future<void> _initialize() async {
    if (_ready) return;

    await WidgetsBinding.instance.endOfFrame;

    try {
      await PreferencesStore.instance.ensureInitialized();
      appLog.d('✅ Platform channels ready');
    } catch (error, stackTrace) {
      appLog.e(
        '⚡ Platform warm-up deferred',
        error: error,
        stackTrace: stackTrace,
      );
    }

    _ready = true;
  }
}
