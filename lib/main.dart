import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:soutnaqi/app.dart';
import 'package:soutnaqi/core/logging/app_log.dart';
import 'package:soutnaqi/core/services/temp_storage_service.dart';
import 'package:soutnaqi/core/storage/preferences_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(systemNavigationBarContrastEnforced: false),
  );

  appLog.d('🔍 Bootstrapping SoutNaqi…');
  try {
    await PreferencesStore.instance.ensureInitialized();
  } catch (error, stackTrace) {
    appLog.e('❌ Preferences initialization failed: $error', error: error, stackTrace: stackTrace);
  }
  unawaited(TempStorageService.instance.cleanOldTempFiles());
  runApp(const SoutNaqiApp());
}
