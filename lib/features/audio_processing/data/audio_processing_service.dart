import 'package:soutnaqi/features/audio_processing/data/audio_operation.dart';

abstract class AudioProcessingService {
  Future<String> process({
    required String inputPath,
    required AudioOperation operation,
    Duration? trimStart,
    Duration? trimEnd,
  });

  bool get isProcessingSupported;
}
