import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:soutnaqi/core/errors/app_exception.dart';
import 'package:soutnaqi/core/logging/app_log.dart';
import 'package:soutnaqi/features/media/data/models/media_file.dart';
import 'package:soutnaqi/features/waveform/data/waveform_service.dart';
import 'package:soutnaqi/features/waveform/data/waveform_service_stub.dart';
import 'package:uuid/uuid.dart';

WaveformService createPlatformWaveformService() => IoWaveformService();

class IoWaveformService implements WaveformService {
  static const _uuid = Uuid();

  @override
  Future<List<double>> extractPeaks({
    required MediaFile media,
    int barCount = 120,
  }) {
    if (media.hasLocalPath) {
      return _extractFromPath(media.path!, barCount: barCount);
    }
    return StubWaveformService().extractPeaks(media: media, barCount: barCount);
  }

  Future<List<double>> _extractFromPath(
    String inputPath, {
    required int barCount,
  }) async {
    appLog.d('🔍 Extracting waveform peaks…');
    final directory = await getTemporaryDirectory();
    final rawPath = '${directory.path}/waveform_${_uuid.v4()}.raw';
    final command =
        '-y -i "$inputPath" -ac 1 -ar 8000 -f s16le "$rawPath"';

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();
    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getAllLogsAsString();
      appLog.e('❌ Waveform extraction failed', error: logs);
      throw AppException(messageKey: 'waveformFailed', cause: logs);
    }

    try {
      final bytes = await File(rawPath).readAsBytes();
      return _peaksFromPcm(bytes, barCount: barCount);
    } finally {
      final rawFile = File(rawPath);
      if (rawFile.existsSync()) {
        await rawFile.delete();
      }
    }
  }

  List<double> _peaksFromPcm(Uint8List bytes, {required int barCount}) {
    final sampleCount = bytes.length ~/ 2;
    if (sampleCount == 0) {
      return List<double>.filled(barCount, 0.1);
    }

    final samplesPerBar = max(1, (sampleCount / barCount).ceil());
    final peaks = <double>[];

    for (var bar = 0; bar < barCount; bar++) {
      final startSample = bar * samplesPerBar;
      final endSample = min(startSample + samplesPerBar, sampleCount);
      var maxPeak = 0;

      for (var sampleIndex = startSample; sampleIndex < endSample; sampleIndex++) {
        final offset = sampleIndex * 2;
        if (offset + 1 >= bytes.length) break;
        final value = ByteData.sublistView(bytes, offset, offset + 2)
            .getInt16(0, Endian.little)
            .abs();
        if (value > maxPeak) maxPeak = value;
      }

      peaks.add(maxPeak / 32768.0);
    }

    appLog.d('✅ Waveform peaks extracted');
    return peaks;
  }
}
