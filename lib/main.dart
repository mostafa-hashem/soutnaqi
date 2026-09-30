import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:soutnaqi/app.dart';
import 'package:soutnaqi/core/logging/app_log.dart';
import 'package:soutnaqi/core/services/temp_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(systemNavigationBarContrastEnforced: false),
  );

  appLog.d('🔍 Bootstrapping SoutNaqi…');
  unawaited(TempStorageService.instance.cleanOldTempFiles());
  runApp(const SoutNaqiApp());
}
