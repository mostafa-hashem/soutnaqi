import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:soutnaqi/core/logging/app_log.dart';

class PreferencesStore {
  PreferencesStore._();

  static final PreferencesStore instance = PreferencesStore._();

  SharedPreferences? _preferences;
  Future<void>? _initializing;

  @visibleForTesting
  void resetForTesting() {
    _preferences = null;
    _initializing = null;
  }

  Future<void> ensureInitialized() async {
    if (_preferences != null) return;
    if (_initializing != null) {
      await _initializing;
      return;
    }
    try {
      final initFuture = _openWithRetry();
      _initializing = initFuture;
      await initFuture;
    } catch (error) {
      _initializing = null;
      rethrow;
    }
  }

  Future<SharedPreferences> get preferences async {
    await ensureInitialized();
    _preferences ??= await SharedPreferences.getInstance();
    return _preferences!;
  }

  Future<void> _openWithRetry() async {
    if (_preferences != null) return;

    Object? lastError;
    for (var attempt = 0; attempt < 8; attempt++) {
      try {
        _preferences = await SharedPreferences.getInstance();
        return;
      } catch (error) {
        lastError = error;
        appLog.e(
          '❌ SharedPreferences not ready (attempt ${attempt + 1})',
          error: error,
        );
        await Future<void>.delayed(
          Duration(milliseconds: 100 * (attempt + 1)),
        );
      }
    }

    throw lastError ?? StateError('SharedPreferences unavailable');
  }
}
