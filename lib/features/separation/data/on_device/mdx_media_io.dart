import 'dart:async';

import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new_min/return_code.dart';
import 'package:soutnaqi/core/errors/app_exception.dart';
import 'package:soutnaqi/core/logging/app_log.dart';
import 'package:soutnaqi/features/separation/data/on_device/on_device_model_spec.dart';
import 'package:soutnaqi/features/separation/data/separation_cancel_token.dart';

/// FFmpeg demuxes/resamples locally and encodes the separated PCM once.
class MdxMediaIo {
  MdxMediaIo._();

  static const _rate = OnDeviceModelSpec.sampleRate;
  static const _channels = OnDeviceModelSpec.channels;
  static const _localInput = ['-protocol_whitelist', 'file'];

  static List<String> decodeArguments({
    required String source,
    required String pcm,
    required bool video,
    Duration? start,
    Duration? end,
  }) => [
    '-y',
    '-nostdin',
    if (video) ...['-copyts', '-start_at_zero'],
    if (start != null) ...['-ss', _seconds(start)],
    ..._localInput,
    '-i',
    source,
    if (end != null) ...['-t', _seconds(end - (start ?? Duration.zero))],
    '-map',
    '0:a:0',
    '-vn',
    '-sn',
    '-dn',
    if (video) ...['-af', 'aresample=$_rate:async=1:first_pts=0'],
    '-ar',
    '$_rate',
    '-ac',
    '$_channels',
    '-c:a',
    'pcm_f32le',
    '-f',
    'f32le',
    pcm,
  ];

  static List<String> encodeArguments({
    required String vocals,
    required String destination,
    String? video,
    String? mix,
  }) {
    final voiceTrack = video == null ? 0 : 1;
    final audioTrack = mix == null ? '$voiceTrack:a:0' : '[instrumental]';
    final instrumentalFilter =
        '[$voiceTrack:a:0]volume=-${OnDeviceModelSpec.compensate}[negative];'
        '[${voiceTrack + 1}:a:0][negative]amix=inputs=2:duration=first:normalize=0[instrumental]';
    return [
      '-y',
      '-nostdin',
      if (video != null) ...[
        '-copyts',
        '-start_at_zero',
        ..._localInput,
        '-i',
        video,
      ],
      ..._pcmInput(vocals),
      if (mix != null) ...[
        ..._pcmInput(mix),
        '-filter_complex',
        instrumentalFilter,
      ],
      if (video != null) ...[
        '-map',
        '0:v:0',
        '-c:v',
        'copy',
        '-avoid_negative_ts',
        'disabled',
      ],
      '-map',
      audioTrack,
      '-c:a',
      'aac',
      '-b:a',
      '320k',
      destination,
    ];
  }

  static List<String> _pcmInput(String path) => [
    '-f',
    'f32le',
    '-ar',
    '$_rate',
    '-ac',
    '$_channels',
    ..._localInput,
    '-i',
    path,
  ];

  static String _seconds(Duration duration) =>
      (duration.inMicroseconds / Duration.microsecondsPerSecond)
          .toStringAsFixed(6);

  static Future<void> execute(
    List<String> arguments, {
    SeparationCancelToken? cancelToken,
    bool checkVideoAudio = false,
  }) async {
    cancelToken?.throwIfCancelled();
    final done = Completer<FFmpegSession>();
    final session = await FFmpegKit.executeWithArgumentsAsync(
      arguments,
      done.complete,
    );
    final sessionId = session.getSessionId();
    void cancel() {
      if (sessionId != null) {
        unawaited(
          FFmpegKit.cancel(sessionId).catchError(
            (Object error) =>
                appLog.w('Could not cancel FFmpeg session', error: error),
          ),
        );
      }
    }

    cancelToken?.addCancelListener(cancel);
    try {
      if (cancelToken?.isCancelled ?? false) cancel();
      final result = await done.future;
      cancelToken?.throwIfCancelled();
      if (ReturnCode.isSuccess(await result.getReturnCode())) return;
      final logs = await result.getAllLogsAsString();
      final noAudio =
          checkVideoAudio && (logs?.contains('matches no streams') ?? false);
      throw AppException(
        messageKey: noAudio ? 'videoNoAudioTrack' : 'separationFailed',
        cause: logs,
      );
    } finally {
      cancelToken?.removeCancelListener(cancel);
    }
  }
}
