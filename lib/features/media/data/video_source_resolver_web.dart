import 'package:soutnaqi/features/media/data/video_source_resolver.dart';

VideoSourceResolver createPlatformVideoSourceResolver() =>
    WebVideoSourceResolver();

class WebVideoSourceResolver implements VideoSourceResolver {
  @override
  String? resolve({
    required String? path,
    required List<int>? bytes,
    required String mimeType,
    String? processedPath,
    required bool useProcessed,
  }) {
    if (useProcessed &&
        processedPath != null &&
        processedPath.startsWith('http')) {
      return processedPath;
    }

    if (bytes == null || bytes.isEmpty) return null;
    return Uri.dataFromBytes(bytes, mimeType: mimeType).toString();
  }

  @override
  void disposeBlob(String? uri) {}
}
