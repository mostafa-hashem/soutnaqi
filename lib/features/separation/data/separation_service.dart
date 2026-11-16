import 'package:soutnaqi/features/separation/data/separation_cancel_token.dart';
import 'package:soutnaqi/features/separation/data/separation_progress.dart';
import 'package:soutnaqi/features/separation/data/separation_target.dart';

abstract class SeparationService {
  bool get isSupported;

  Future<String> separate({
    required String inputAudioPath,
    required SeparationTarget target,
    SeparationProgressCallback? onProgress,
    SeparationCancelToken? cancelToken,
  });
}

/// A local engine that can read the original video directly.
abstract interface class MediaSeparationService implements SeparationService {
  @override
  Future<String> separate({
    required String inputAudioPath,
    required SeparationTarget target,
    SeparationProgressCallback? onProgress,
    SeparationCancelToken? cancelToken,
    Duration? start,
    Duration? end,
  });

  Future<String> separateVideo({
    required String videoPath,
    required SeparationTarget target,
    SeparationProgressCallback? onProgress,
    SeparationCancelToken? cancelToken,
  });
}
