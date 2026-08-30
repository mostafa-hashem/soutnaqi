import 'package:soutnaqi/features/media/data/video_source_resolver.dart';

VideoSourceResolver createPlatformVideoSourceResolver() =>
    StubVideoSourceResolver();

class StubVideoSourceResolver implements VideoSourceResolver {
  @override
  String? resolve({
    required String? path,
    required List<int>? bytes,
    required String mimeType,
    String? processedPath,
    required bool useProcessed,
  }) {
    return null;
  }

  @override
  void disposeBlob(String? uri) {}
}
