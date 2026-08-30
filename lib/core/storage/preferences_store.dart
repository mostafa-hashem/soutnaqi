import 'package:shared_preferences/shared_preferences.dart';

import 'package:soutnaqi/core/logging/app_log.dart';

class PreferencesStore {
  PreferencesStore._();

  static final PreferencesStore instance = PreferencesStore._();

  SharedPreferences? _preferences;
  Future<void>? _initializing;

  Future<void> ensureInitialized() {
    return _initializing ??= _openWithRetry();
  }

  Future<SharedPreferences> get preferences async {
    await ensureInitialized();
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
