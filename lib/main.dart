import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:soutnaqi/app.dart';
import 'package:soutnaqi/core/logging/app_log.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarContrastEnforced: false,
    ),
  );

  appLog.d('🔍 Bootstrapping SoutNaqi…');
  runApp(const SoutNaqiApp());
}
