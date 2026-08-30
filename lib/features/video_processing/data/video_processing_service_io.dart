import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:soutnaqi/core/errors/app_exception.dart';
import 'package:soutnaqi/core/logging/app_log.dart';
import 'package:soutnaqi/features/audio_processing/data/ffmpeg_audio_codec.dart';
import 'package:soutnaqi/features/video_processing/data/video_operation.dart';
import 'package:soutnaqi/features/video_processing/data/video_processing_service.dart';
import 'package:uuid/uuid.dart';

VideoProcessingService createPlatformVideoProcessingService() =>
    IoVideoProcessingService();

class IoVideoProcessingService implements VideoProcessingService {
  static const _uuid = Uuid();

  @override
  bool get isProcessingSupported => true;

  @override
  Future<String> process({
    required String inputPath,
    required VideoOperation operation,
  }) async {
    appLog.d('⚡ Starting video processing: $operation');
    final outputPath = await _createOutputPath(inputPath, operation);
    if (operation == VideoOperation.extractAudio) {
      return _extractAudio(inputPath: inputPath, outputPath: outputPath);
    }

    final command = switch (operation) {
      VideoOperation.extractAudio => throw StateError('handled above'),
      VideoOperation.compress =>
        '-y -i "$inputPath" -vcodec libx264 -crf 28 -acodec aac -b:a 128k "$outputPath"',
      VideoOperation.isolateVocals => throw StateError(
          'Separation operations use SeparationService',
        ),
      VideoOperation.isolateMusic => throw StateError(
          'Separation operations use SeparationService',
        ),
    };

    return _runFfmpeg(command, outputPath);
  }

  @override
  Future<String> replaceAudioTrack({
    required String videoPath,
    required String audioPath,
  }) async {
    appLog.d('⚡ Replacing video audio track…');
    final outputPath = await _createMergedVideoOutputPath();
    final command =
        '-y -i "$videoPath" -i "$audioPath" -c:v copy -c:a aac -b:a 192k -map 0:v:0 -map 1:a:0 -shortest "$outputPath"';
    return _runFfmpeg(command, outputPath);
  }

  Future<String> _extractAudio({
    required String inputPath,
    required String outputPath,
  }) async {
    final copyCommand = '-y -i "$inputPath" -vn -c:a copy "$outputPath"';
    final copySession = await FFmpegKit.execute(copyCommand);
    if (ReturnCode.isSuccess(await copySession.getReturnCode())) {
      appLog.d('✅ Audio extracted (stream copy): $outputPath');
      return outputPath;
    }

    appLog.d('⚡ Stream copy failed — re-encoding to AAC…');
    final encodeCommand =
        '-y -i "$inputPath" -vn ${FfmpegAudioCodec.encodeTo(outputPath)}';
    return _runFfmpeg(encodeCommand, outputPath);
  }

  Future<String> _runFfmpeg(String command, String outputPath) async {
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();
    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getAllLogsAsString();
      appLog.e('❌ Video processing failed', error: logs);
      throw AppException(messageKey: 'processingFailed', cause: logs);
    }

    appLog.d('✅ Video processing complete: $outputPath');
    return outputPath;
  }

  Future<String> _createOutputPath(
    String inputPath,
    VideoOperation operation,
  ) async {
    final directory = await getTemporaryDirectory();
    final extension = switch (operation) {
      VideoOperation.extractAudio => FfmpegAudioCodec.outputExtension,
      VideoOperation.compress => 'mp4',
      VideoOperation.isolateVocals => throw StateError(
          'Separation operations use SeparationService',
        ),
      VideoOperation.isolateMusic => throw StateError(
          'Separation operations use SeparationService',
        ),
    };
    return '${directory.path}/soutnaqi_${_uuid.v4()}.$extension';
  }

  Future<String> _createMergedVideoOutputPath() async {
    final directory = await getTemporaryDirectory();
    return '${directory.path}/soutnaqi_${_uuid.v4()}.mp4';
  }
}

Future<void> ensureVideoInputExists(String inputPath) async {
  if (!File(inputPath).existsSync()) {
    throw const AppException(messageKey: 'mediaPickFailed');
  }
}
