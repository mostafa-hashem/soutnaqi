import 'package:soutnaqi/core/errors/app_exception.dart';
import 'package:soutnaqi/features/video_processing/data/video_operation.dart';
import 'package:soutnaqi/features/video_processing/data/video_processing_service.dart';
import 'package:soutnaqi/features/video_processing/data/video_to_audio_options.dart';

VideoProcessingService createPlatformVideoProcessingService() =>
    StubVideoProcessingService();

class StubVideoProcessingService implements VideoProcessingService {
  @override
  bool get isProcessingSupported => false;

  @override
  Future<String> process({
    required String inputPath,
    required VideoOperation operation,
    double speed = 1.0,
  }) {
    return _unsupported();
  }

  @override
  Future<String> convertVideoToAudio({
    required String inputPath,
    required VideoToAudioOptions options,
  }) {
    return _unsupported();
  }

  @override
  Future<String> replaceAudioTrack({
    required String videoPath,
    required String audioPath,
  }) {
    return _unsupported();
  }

  Future<String> _unsupported() {
    return Future.error(
      const AppException(
        messageKey: 'processingWebUnsupported',
        type: AppExceptionType.permission,
      ),
    );
  }
}
