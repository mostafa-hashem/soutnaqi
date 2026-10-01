import 'package:soutnaqi/core/logging/app_log.dart';
import 'package:url_launcher/url_launcher.dart';

Future<bool> launchAppUrl(String url) async {
  try {
    final uri = Uri.parse(url);
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (error, stackTrace) {
    appLog.e('Failed to launch URL: $url', error: error, stackTrace: stackTrace);
    return false;
  }
}
