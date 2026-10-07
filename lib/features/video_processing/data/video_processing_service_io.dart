import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:soutnaqi/core/errors/app_exception.dart';
import 'package:soutnaqi/core/logging/app_log.dart';
import 'package:soutnaqi/features/audio_processing/data/ffmpeg_audio_codec.dart';
import 'package:soutnaqi/features/video_processing/data/video_operation.dart';
import 'package:soutnaqi/features/video_processing/data/video_processing_service.dart';
import 'package:soutnaqi/features/video_processing/data/video_to_audio_options.dart';
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
      return convertVideoToAudio(
        inputPath: inputPath,
        options: const VideoToAudioOptions(),
      );
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
      VideoOperation.muteVideo =>
        '-y -i "$inputPath" -c:v copy -an "$outputPath"',
      VideoOperation.replaceAudio => throw StateError(
          'Use replaceAudioTrack directly',
        ),
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
  Future<String> convertVideoToAudio({
    required String inputPath,
    required VideoToAudioOptions options,
  }) async {
    appLog.d(
      '⚡ Converting video to audio: format=${options.format.extension}, bitrate=${options.bitrate.kbps}k, channels=${options.channels.channels}',
    );
    final directory = await getTemporaryDirectory();
    final outputPath =
        '${directory.path}/soutnaqi_${_uuid.v4()}.${options.format.extension}';

    final trimArgs = _buildTrimArgs(options.trimStart, options.trimEnd);

    final filters = <String>[];
    if (options.reduceNoise) {
      filters.add('afftdn=nf=-25');
    }
    if (options.normalizeVolume) {
      filters.add('loudnorm=I=-16:TP=-1.5:LRA=11');
    }
    final filterArg = filters.isNotEmpty ? '-af "${filters.join(',')}"' : '';
    final channelArg = '-ac ${options.channels.channels}';

    // Stream copy fast-path if format allows and no processing requested
    final canStreamCopy = filters.isEmpty &&
        options.channels == AudioChannels.stereo &&
        options.trimStart == null &&
        options.trimEnd == null;

    if (canStreamCopy) {
      final copyCommand = '-y -i "$inputPath" -vn -c:a copy "$outputPath"';
      final copySession = await FFmpegKit.execute(copyCommand);
      if (ReturnCode.isSuccess(await copySession.getReturnCode())) {
        appLog.d('✅ Audio extracted (stream copy): $outputPath');
        return outputPath;
      }
      appLog.d('⚡ Stream copy skipped or incompatible — proceeding to encode…');
    }

    final encodeArgs = switch (options.format) {
      AudioOutputFormat.m4a => '-c:a aac -b:a ${options.bitrate.kbps}k',
      AudioOutputFormat.wav => '-c:a pcm_s16le -ar 44100',
      AudioOutputFormat.flac => '-c:a flac',
      AudioOutputFormat.mp3 => '-c:a libmp3lame -b:a ${options.bitrate.kbps}k',
    };

    final command = [
      trimArgs,
      '-y',
      '-i "$inputPath"',
      '-vn',
      channelArg,
      filterArg,
      encodeArgs,
      '"$outputPath"',
    ].where((part) => part.isNotEmpty).join(' ');

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();
    if (ReturnCode.isSuccess(returnCode)) {
      appLog.d('✅ Video to audio conversion complete: $outputPath');
      return outputPath;
    }

    final logs = await session.getAllLogsAsString();

    // Check for missing audio track
    if (logs != null &&
        (logs.contains('does not contain any stream') ||
            logs.contains('matches no streams') ||
            logs.contains('Output file does not contain any stream'))) {
      appLog.e('❌ Video has no audio track: $logs');
      throw const AppException(messageKey: 'videoNoAudioTrack');
    }

    // Graceful fallback for MP3 if libmp3lame is not present in min FFmpeg build
    if (options.format == AudioOutputFormat.mp3 &&
        logs != null &&
        (logs.contains('Unknown encoder') || logs.contains('Encoder not found'))) {
      appLog.d('⚡ libmp3lame unavailable — trying native mp3 encoder…');
      final fallbackMp3Command = [
        trimArgs,
        '-y',
        '-i "$inputPath"',
        '-vn',
        channelArg,
        filterArg,
        '-c:a mp3 -b:a ${options.bitrate.kbps}k',
        '"$outputPath"',
      ].where((part) => part.isNotEmpty).join(' ');

      final mp3Session = await FFmpegKit.execute(fallbackMp3Command);
      if (ReturnCode.isSuccess(await mp3Session.getReturnCode())) {
        appLog.d('✅ Converted using native mp3 encoder: $outputPath');
        return outputPath;
      }

      appLog.d('⚡ Native mp3 encoder also unavailable — converting to AAC (.m4a)…');
      final fallbackAacPath =
          '${directory.path}/soutnaqi_${_uuid.v4()}.m4a';
      final fallbackAacCommand = [
        trimArgs,
        '-y',
        '-i "$inputPath"',
        '-vn',
        channelArg,
        filterArg,
        '-c:a aac -b:a ${options.bitrate.kbps}k',
        '"$fallbackAacPath"',
      ].where((part) => part.isNotEmpty).join(' ');

      return _runFfmpeg(fallbackAacCommand, fallbackAacPath);
    }

    appLog.e('❌ Video to audio conversion failed', error: logs);
    throw AppException(messageKey: 'processingFailed', cause: logs);
  }

  String _buildTrimArgs(Duration? trimStart, Duration? trimEnd) {
    final start = trimStart ?? Duration.zero;
    final startArg =
        start.inMilliseconds > 0 ? '-ss ${_formatDuration(start)}' : '';
    final endArg = trimEnd != null ? '-to ${_formatDuration(trimEnd)}' : '';
    return '$startArg $endArg'.trim();
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inMilliseconds / 1000;
    return totalSeconds.toStringAsFixed(3);
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
      VideoOperation.muteVideo => 'mp4',
      VideoOperation.replaceAudio => 'mp4',
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
