import 'package:soutnaqi/core/errors/app_exception.dart';
import 'package:soutnaqi/features/separation/data/separation_progress.dart';
import 'package:soutnaqi/features/separation/data/separation_service.dart';
import 'package:soutnaqi/features/separation/data/separation_target.dart';

SeparationService createPlatformSeparationService() => StubSeparationService();

SeparationService createLocalSeparationService() => StubSeparationService();

class StubSeparationService implements SeparationService {
  @override
  bool get isSupported => false;

  @override
  Future<String> separate({
    required String inputAudioPath,
    required SeparationTarget target,
    SeparationProgressCallback? onProgress,
  }) {
    throw const AppException(messageKey: 'separationNotConfigured');
  }
}
