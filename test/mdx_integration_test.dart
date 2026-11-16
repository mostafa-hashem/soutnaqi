import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:soutnaqi/features/separation/data/on_device/mdx_media_io.dart';
import 'package:soutnaqi/features/separation/data/on_device/on_device_model_repository.dart';
import 'package:soutnaqi/features/separation/data/on_device/on_device_separation_engine.dart';
import 'package:soutnaqi/features/separation/data/on_device/on_device_separation_service.dart';
import 'package:soutnaqi/features/separation/data/separation_cancel_token.dart';
import 'package:soutnaqi/features/separation/data/separation_progress.dart';
import 'package:soutnaqi/features/separation/data/separation_target.dart';

void main() {
  final ffmpeg = Platform.environment['SOUTNAQI_TEST_FFMPEG'];
  final model = Platform.environment['SOUTNAQI_TEST_MODEL'];
  late Directory temp;

  setUp(
    () async => temp = await Directory.systemTemp.createTemp('soutnaqi-test'),
  );
  tearDown(() => temp.delete(recursive: true));

  test(
    'FFmpeg decodes selected mono 48 kHz WAV into stereo float at 44.1 kHz',
    () async {
      final source = '${temp.path}/audio source.wav';
      final pcm = '${temp.path}/clip.pcm';
      await _ffmpeg(ffmpeg!, [
        '-f',
        'lavfi',
        '-i',
        'sine=sample_rate=48000:duration=1',
        source,
      ]);
      await _ffmpeg(
        ffmpeg,
        MdxMediaIo.decodeArguments(
          source: source,
          pcm: pcm,
          video: false,
          start: const Duration(milliseconds: 200),
          end: const Duration(milliseconds: 700),
        ),
      );
      expect(await File(pcm).length(), 22050 * 8);
    },
    skip: ffmpeg == null,
  );

  test(
    'FFmpeg keeps delayed audio aligned and preserves video packets',
    () async {
      final source = '${temp.path}/original video.mp4';
      final pcm = '${temp.path}/separated.pcm';
      final output = '${temp.path}/export.mp4';
      final outputPcm = '${temp.path}/export.pcm';
      await _ffmpeg(ffmpeg!, [
        '-f',
        'lavfi',
        '-i',
        'testsrc2=s=160x90:r=25:d=1.4',
        '-itsoffset',
        '0.25',
        '-f',
        'lavfi',
        '-i',
        'sine=frequency=880:sample_rate=48000:duration=0.7',
        '-map',
        '0:v:0',
        '-map',
        '1:a:0',
        '-c:v',
        'libx264',
        '-c:a',
        'aac',
        source,
      ]);
      await _ffmpeg(
        ffmpeg,
        MdxMediaIo.decodeArguments(source: source, pcm: pcm, video: true),
      );
      await _ffmpeg(
        ffmpeg,
        MdxMediaIo.encodeArguments(
          vocals: pcm,
          destination: output,
          video: source,
        ),
      );
      await _ffmpeg(
        ffmpeg,
        MdxMediaIo.decodeArguments(source: output, pcm: outputPcm, video: true),
      );

      for (final path in [pcm, outputPcm]) {
        final data = ByteData.sublistView(await File(path).readAsBytes());
        expect(_peak(data, 0, 7000), lessThan(0.005));
        expect(_peak(data, 15000, 18000), greaterThan(0.03));
      }
      Future<String> videoHash(String path) => _ffmpeg(ffmpeg, [
        '-i',
        path,
        '-map',
        '0:v:0',
        '-c:v',
        'copy',
        '-f',
        'hash',
        '-hash',
        'sha256',
        '-',
      ]);
      expect(await videoHash(output), await videoHash(source));
    },
    skip: ffmpeg == null,
  );

  test(
    'full service reuses the neural result for the complementary stem',
    () async {
      final source = '${temp.path}/source.wav';
      await _ffmpeg(ffmpeg!, [
        '-f',
        'lavfi',
        '-i',
        'sine=frequency=330:sample_rate=48000:duration=1',
        source,
      ]);
      var ffmpegRuns = 0;
      final service = OnDeviceSeparationService(
        modelRepository: _LocalModelRepository(model!),
        temporaryDirectory: () async => temp,
        executeMedia: (args, {cancelToken, checkVideoAudio = false}) async {
          ffmpegRuns++;
          await _ffmpeg(ffmpeg, args);
        },
      );

      final engine = OnDeviceSeparationEngine.instance;
      try {
        final vocals = await service.separate(
          inputAudioPath: source,
          target: SeparationTarget.vocals,
        );
        final music = await service.separate(
          inputAudioPath: source,
          target: SeparationTarget.instrumental,
          onProgress: (progress) {
            expect(progress.stage, isNot(SeparationStage.separating));
          },
        );
        expect(ffmpegRuns, 3);
        expect(await File(vocals).length(), greaterThan(0));
        expect(await File(music).length(), greaterThan(0));
        final output = '${temp.path}/music.pcm';
        await _ffmpeg(
          ffmpeg,
          MdxMediaIo.decodeArguments(source: music, pcm: output, video: false),
        );
        final samples = ByteData.sublistView(await File(output).readAsBytes());
        expect(_peak(samples, 4410, 8820), greaterThan(0.01));
      } finally {
        await engine.dispose();
      }
    },
    skip: ffmpeg == null || model == null,
  );

  test('FFmpeg subtracts the estimated vocals from the mix', () async {
    final wav = '${temp.path}/sine.wav';
    final pcm = '${temp.path}/sine.pcm';
    final output = '${temp.path}/residual.m4a';
    final outputPcm = '${temp.path}/residual.pcm';
    await _ffmpeg(ffmpeg!, [
      '-f',
      'lavfi',
      '-i',
      'sine=frequency=880:sample_rate=44100:duration=1',
      wav,
    ]);
    await _ffmpeg(
      ffmpeg,
      MdxMediaIo.decodeArguments(source: wav, pcm: pcm, video: false),
    );
    await _ffmpeg(
      ffmpeg,
      MdxMediaIo.encodeArguments(vocals: pcm, mix: pcm, destination: output),
    );
    await _ffmpeg(
      ffmpeg,
      MdxMediaIo.decodeArguments(source: output, pcm: outputPcm, video: false),
    );
    final samples = ByteData.sublistView(await File(outputPcm).readAsBytes());
    expect(_peak(samples, 10000, 20000), inInclusiveRange(0.001, 0.006));
  }, skip: ffmpeg == null);

  test(
    'native model runs twice and recovers from cancellation',
    () async {
      final engine = OnDeviceSeparationEngine.instance;
      final input = '${temp.path}/input.pcm';
      const count = 44100;
      final samples = ByteData(count * 8);
      for (var i = 0; i < count; i++) {
        final sample = math.sin(2 * math.pi * 440 * i / count) * 0.2;
        samples.setFloat32(i * 8, sample, Endian.little);
        samples.setFloat32(i * 8 + 4, sample, Endian.little);
      }
      await File(input).writeAsBytes(samples.buffer.asUint8List());

      Future<void> run(
        String path,
        SeparationTarget target, {
        bool cancel = false,
      }) {
        final token = SeparationCancelToken();
        return engine.process(
          modelPath: model!,
          inputPath: input,
          outputPath: path,
          target: target,
          cancelToken: token,
          onProgress: (progress) {
            if (cancel && progress.chunkIndex == 0) token.cancel();
          },
        );
      }

      final vocals = '${temp.path}/vocals.pcm';
      final music = '${temp.path}/music.pcm';
      try {
        await run(vocals, SeparationTarget.vocals);
        final prediction = ByteData.sublistView(
          await File(vocals).readAsBytes(),
        );
        expect(prediction.lengthInBytes, count * 8);
        expect(_peak(prediction, 0, count), greaterThan(1e-6));
        await expectLater(
          run(
            '${temp.path}/cancelled.pcm',
            SeparationTarget.vocals,
            cancel: true,
          ),
          throwsA(
            predicate(
              (Object error) =>
                  error.toString().contains('separationCancelled'),
            ),
          ),
        );
        await run(music, SeparationTarget.instrumental);
        final residual = ByteData.sublistView(await File(music).readAsBytes());
        expect(residual.lengthInBytes, count * 8);
        for (var i = 0; i < count * 8; i += 256) {
          expect(
            residual.getFloat32(i, Endian.little) +
                prediction.getFloat32(i, Endian.little) * 1.021,
            closeTo(samples.getFloat32(i, Endian.little), 1e-5),
          );
        }
      } finally {
        await engine.dispose();
      }
    },
    skip: model == null,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

Future<String> _ffmpeg(String executable, List<String> arguments) async {
  final result = await Process.run(executable, [
    '-hide_banner',
    '-loglevel',
    'error',
    ...arguments,
  ]);
  expect(result.exitCode, 0, reason: result.stderr.toString());
  return result.stdout.toString();
}

double _peak(ByteData data, int from, int to) {
  var peak = 0.0;
  for (var i = from; i < to; i++) {
    peak = math.max(peak, data.getFloat32(i * 8, Endian.little).abs());
  }
  return peak;
}

class _LocalModelRepository implements OnDeviceModelRepository {
  _LocalModelRepository(this.path);
  final String path;

  @override
  Future<bool> isModelCached() async => true;

  @override
  Future<String> modelPath() async => path;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
