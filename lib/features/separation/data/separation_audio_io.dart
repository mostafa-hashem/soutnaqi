import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min/return_code.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:soutnaqi/core/errors/app_exception.dart';
import 'package:soutnaqi/core/logging/app_log.dart';
import 'package:soutnaqi/features/audio_processing/data/ffmpeg_audio_codec.dart';
import 'package:uuid/uuid.dart';

class SeparationAudioIo {
  SeparationAudioIo._();

  static const _uuid = Uuid();

  static Future<String> prepareWavInput(String localPath) async {
    final extension = p.extension(localPath).toLowerCase();
    if (extension == '.wav') {
      return localPath;
    }

    appLog.d('🔍 Converting input to WAV for Demucs…');
    final directory = await getTemporaryDirectory();
    final wavPath = '${directory.path}/soutnaqi_${_uuid.v4()}.wav';
    final command =
        '-y -i "$localPath" -ar 44100 -ac 2 -c:a pcm_s16le "$wavPath"';
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();
    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getAllLogsAsString();
      throw AppException(messageKey: 'separationFailed', cause: logs);
    }

    appLog.d('✅ Input converted to WAV');
    return wavPath;
  }

  static Future<String> encodeWavToM4a(String wavPath) async {
    final directory = await getTemporaryDirectory();
    final outputPath =
        '${directory.path}/soutnaqi_${_uuid.v4()}.${FfmpegAudioCodec.outputExtension}';
    final command =
        '-y -i "$wavPath" ${FfmpegAudioCodec.encodeTo(outputPath)}';
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    try {
      await File(wavPath).delete();
    } catch (_) {}

    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getAllLogsAsString();
      throw AppException(messageKey: 'separationFailed', cause: logs);
    }

    return outputPath;
  }
}
