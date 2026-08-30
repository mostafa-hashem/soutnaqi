import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:soutnaqi/core/errors/app_exception.dart';
import 'package:soutnaqi/core/logging/app_log.dart';
import 'package:soutnaqi/features/audio_processing/data/audio_operation.dart';
import 'package:soutnaqi/features/audio_processing/data/audio_processing_service.dart';
import 'package:soutnaqi/features/audio_processing/data/ffmpeg_audio_codec.dart';
import 'package:uuid/uuid.dart';

AudioProcessingService createPlatformAudioProcessingService() =>
    IoAudioProcessingService();

class IoAudioProcessingService implements AudioProcessingService {
  static const _uuid = Uuid();

  @override
  bool get isProcessingSupported => true;

  @override
  Future<String> process({
    required String inputPath,
    required AudioOperation operation,
    Duration? trimStart,
    Duration? trimEnd,
  }) async {
    appLog.d('⚡ Starting audio processing: $operation');
    final outputPath = await _createOutputPath();
    final command = _commandFor(
      inputPath: inputPath,
      outputPath: outputPath,
      operation: operation,
      trimStart: trimStart,
      trimEnd: trimEnd,
    );

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getAllLogsAsString();
      appLog.e('❌ FFmpeg failed', error: logs);
      throw AppException(
        messageKey: 'processingFailed',
        cause: logs,
      );
    }

    appLog.d('✅ Audio processing complete: $outputPath');
    return outputPath;
  }

  String _commandFor({
    required String inputPath,
    required String outputPath,
    required AudioOperation operation,
    Duration? trimStart,
    Duration? trimEnd,
  }) {
    final trimArgs = _trimArgs(trimStart, trimEnd);
    final encode = FfmpegAudioCodec.encodeTo(outputPath);

    return switch (operation) {
      AudioOperation.normalize =>
        '$trimArgs -y -i "$inputPath" -af "loudnorm=I=-16:TP=-1.5:LRA=11" $encode',
      AudioOperation.noiseReduction =>
        '$trimArgs -y -i "$inputPath" -af "afftdn=nf=-25" $encode',
      AudioOperation.trim => '$trimArgs -y -i "$inputPath" $encode',
      AudioOperation.isolateVocals => throw StateError(
          'Separation operations use SeparationService',
        ),
      AudioOperation.isolateMusic => throw StateError(
          'Separation operations use SeparationService',
        ),
    };
  }

  String _trimArgs(Duration? trimStart, Duration? trimEnd) {
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

  Future<String> _createOutputPath() async {
    final directory = await getTemporaryDirectory();
    return '${directory.path}/soutnaqi_${_uuid.v4()}.${FfmpegAudioCodec.outputExtension}';
  }
}

Future<void> ensureInputExists(String inputPath) async {
  if (!File(inputPath).existsSync()) {
    throw const AppException(messageKey: 'mediaPickFailed');
  }
}
