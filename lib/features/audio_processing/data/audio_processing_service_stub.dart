import 'package:soutnaqi/core/errors/app_exception.dart';
import 'package:soutnaqi/features/audio_processing/data/audio_operation.dart';
import 'package:soutnaqi/features/audio_processing/data/audio_processing_service.dart';

AudioProcessingService createPlatformAudioProcessingService() =>
    StubAudioProcessingService();

class StubAudioProcessingService implements AudioProcessingService {
  @override
  bool get isProcessingSupported => false;

  @override
  Future<String> process({
    required String inputPath,
    required AudioOperation operation,
    Duration? trimStart,
    Duration? trimEnd,
  }) {
    return Future.error(
      const AppException(
        messageKey: 'processingWebUnsupported',
        type: AppExceptionType.permission,
      ),
    );
  }
}
