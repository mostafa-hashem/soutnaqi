import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:soutnaqi/core/logging/app_log.dart';

/// Listens for media files shared or opened from external apps (e.g. Audio Players,
/// Sound Recorders, File Managers).
class IncomingMediaService {
  IncomingMediaService._();

  static final IncomingMediaService instance = IncomingMediaService._();

  static const _channel = MethodChannel('com.soutnaqi.app/incoming_media');

  void Function(String filePath)? _onMediaReceived;

  void initialize({required void Function(String filePath) onMediaReceived}) {
    if (kIsWeb || !Platform.isAndroid) return;
    _onMediaReceived = onMediaReceived;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onMediaReceived') {
        final path = call.arguments as String?;
        if (path != null && path.isNotEmpty) {
          appLog.d('⚡ Received media from external app: $path');
          _onMediaReceived?.call(path);
        }
      }
    });

    _checkInitialMedia();
  }

  Future<void> _checkInitialMedia() async {
    try {
      final initialPath = await _channel.invokeMethod<String>('getInitialMedia');
      if (initialPath != null && initialPath.isNotEmpty) {
        appLog.d('⚡ Received initial media from launch intent: $initialPath');
        _onMediaReceived?.call(initialPath);
      }
    } catch (error) {
      appLog.w('⚠️ Error checking initial media: $error');
    }
  }
}
