import 'package:package_info_plus/package_info_plus.dart';
import 'package:soutnaqi/core/logging/app_log.dart';

class AppInfoService {
  AppInfoService._();
  static final AppInfoService instance = AppInfoService._();

  String _version = '1.0.2';
  String _buildNumber = '7';

  String get version => _version;
  String get buildNumber => _buildNumber;

  /// Returns formatted version string, e.g. "1.0.2 (7)"
  String get displayVersion {
    if (_buildNumber.isEmpty) return _version;
    return '$_version ($_buildNumber)';
  }

  /// Returns clean semantic version, e.g. "1.0.2"
  String get versionName => _version;

  Future<void> init() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (info.version.isNotEmpty) {
        _version = info.version;
        _buildNumber = info.buildNumber;
      }
      appLog.d('📱 App version loaded: $_version ($_buildNumber)');
    } catch (e) {
      appLog.d('⚠️ Could not load package info, using default: $e');
    }
  }
}
