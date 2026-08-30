import 'package:soutnaqi/features/media/data/video_source_platform.dart';

String? resolveVideoSourceUri({
  required String? path,
  required List<int>? bytes,
  required String mimeType,
  String? processedPath,
  required bool useProcessed,
}) {
  return createVideoSourceResolver().resolve(
    path: path,
    bytes: bytes,
    mimeType: mimeType,
    processedPath: processedPath,
    useProcessed: useProcessed,
  );
}

abstract class VideoSourceResolver {
  String? resolve({
    required String? path,
    required List<int>? bytes,
    required String mimeType,
    String? processedPath,
    required bool useProcessed,
  });

  void disposeBlob(String? uri);
}
