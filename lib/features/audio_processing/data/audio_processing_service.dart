import 'package:soutnaqi/features/audio_processing/data/audio_operation.dart';

abstract class AudioProcessingService {
  Future<String> process({
    required String inputPath,
    required AudioOperation operation,
    Duration? trimStart,
    Duration? trimEnd,
    double speed = 1.0,
  });

  bool get isProcessingSupported;
}
