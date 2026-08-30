import 'package:soutnaqi/features/video_processing/data/video_operation.dart';

abstract class VideoProcessingService {
  Future<String> process({
    required String inputPath,
    required VideoOperation operation,
  });

  /// Replaces the video's audio track with [audioPath] and returns an MP4 path.
  Future<String> replaceAudioTrack({
    required String videoPath,
    required String audioPath,
  });

  bool get isProcessingSupported;
}
