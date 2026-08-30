import 'package:soutnaqi/features/media/data/video_source_resolver.dart';

VideoSourceResolver createPlatformVideoSourceResolver() =>
    IoVideoSourceResolver();

class IoVideoSourceResolver implements VideoSourceResolver {
  @override
  String? resolve({
    required String? path,
    required List<int>? bytes,
    required String mimeType,
    String? processedPath,
    required bool useProcessed,
  }) {
    final sourcePath = useProcessed && processedPath != null
        ? processedPath
        : path;
    if (sourcePath == null || sourcePath.isEmpty) return null;
    return Uri.file(sourcePath).toString();
  }

  @override
  void disposeBlob(String? uri) {}
}
