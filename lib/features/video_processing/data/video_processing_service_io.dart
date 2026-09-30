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
    double speed = 1.0,
  }) async {
    appLog.d('⚡ Starting video processing: $operation (speed: $speed)');
    final outputPath = await _createOutputPath(inputPath, operation);
    if (operation == VideoOperation.extractAudio) {
      return _extractAudio(inputPath: inputPath, outputPath: outputPath);
    }
    if (operation == VideoOperation.changeSpeed) {
      return _changeSpeed(
        inputPath: inputPath,
        outputPath: outputPath,
        speed: speed,
      );
    }

    final command = switch (operation) {
      VideoOperation.extractAudio => throw StateError('handled above'),
      VideoOperation.changeSpeed => throw StateError('handled above'),
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

  Future<String> _changeSpeed({
    required String inputPath,
    required String outputPath,
    required double speed,
  }) async {
    final pts = (1.0 / speed).toStringAsFixed(4);
    final atempo = speed.toStringAsFixed(2);
    final commandWithAudio =
        '-y -i "$inputPath" -filter_complex "[0:v]setpts=$pts*PTS[v];[0:a]atempo=$atempo[a]" -map "[v]" -map "[a]" -c:v libx264 -crf 23 -c:a aac -b:a 192k "$outputPath"';

    final session = await FFmpegKit.execute(commandWithAudio);
    if (ReturnCode.isSuccess(await session.getReturnCode())) {
      appLog.d('✅ Video speed changed: $outputPath');
      return outputPath;
    }

    appLog.d('⚡ Combined speed filter failed — attempting video-only speed adjustment…');
    final commandVideoOnly =
        '-y -i "$inputPath" -vf "setpts=$pts*PTS" -c:v libx264 -crf 23 -an "$outputPath"';
    return _runFfmpeg(commandVideoOnly, outputPath);
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
      VideoOperation.changeSpeed => 'mp4',
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
