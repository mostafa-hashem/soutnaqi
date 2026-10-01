import 'package:soutnaqi/features/video_processing/data/video_operation.dart';
import 'package:soutnaqi/features/video_processing/data/video_to_audio_options.dart';

abstract class VideoProcessingService {
  Future<String> process({
    required String inputPath,
    required VideoOperation operation,
    double speed = 1.0,
  });

  /// Converts a video file into an audio file according to the given [options].
  Future<String> convertVideoToAudio({
    required String inputPath,
    required VideoToAudioOptions options,
  });

  /// Replaces the video's audio track with [audioPath] and returns an MP4 path.
  Future<String> replaceAudioTrack({
    required String videoPath,
    required String audioPath,
  });

  bool get isProcessingSupported;
}
