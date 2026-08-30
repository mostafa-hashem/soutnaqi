import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:soutnaqi/core/config/app_env.dart';
import 'package:soutnaqi/core/errors/app_exception.dart';
import 'package:soutnaqi/core/logging/app_log.dart';
import 'package:soutnaqi/features/separation/data/separation_audio_io.dart';
import 'package:soutnaqi/features/separation/data/separation_service.dart';
import 'package:soutnaqi/features/separation/data/separation_target.dart';
import 'package:uuid/uuid.dart';

SeparationService createLocalSeparationService() => LocalSeparationService();

class LocalSeparationService implements SeparationService {
  LocalSeparationService({http.Client? client})
      : _client = client ?? http.Client();

  static const _uuid = Uuid();
  static const _requestTimeout = Duration(minutes: 15);

  final http.Client _client;

  @override
  bool get isSupported => AppEnv.isLocalSeparationConfigured;

  @override
  Future<String> separate({
    required String inputAudioPath,
    required SeparationTarget target,
  }) async {
    if (!isSupported) {
      throw const AppException(messageKey: 'separationNotConfigured');
    }

    appLog.d('⚡ Starting local Demucs separation: $target');
    var preparedPath = inputAudioPath;
    try {
      preparedPath = await SeparationAudioIo.prepareWavInput(inputAudioPath);
      final wavBytes = await _requestSeparation(
        wavPath: preparedPath,
        target: target,
      );
      final directory = await getTemporaryDirectory();
      final wavOutput = '${directory.path}/soutnaqi_${_uuid.v4()}.wav';
      await File(wavOutput).writeAsBytes(wavBytes);
      final outputPath = await SeparationAudioIo.encodeWavToM4a(wavOutput);
      appLog.d('✅ Local separation complete: $outputPath');
      return outputPath;
    } on AppException {
      rethrow;
    } on SocketException catch (error) {
      appLog.e('❌ Local separation server unreachable', error: error);
      throw AppException(
        messageKey: 'separationServerUnreachable',
        type: AppExceptionType.network,
        cause: error,
      );
    } catch (error) {
      appLog.e('❌ Local separation failed', error: error);
      throw AppException(messageKey: 'separationFailed', cause: error);
    } finally {
      if (preparedPath != inputAudioPath) {
        try {
          await File(preparedPath).delete();
        } catch (_) {}
      }
    }
  }

  Future<List<int>> _requestSeparation({
    required String wavPath,
    required SeparationTarget target,
  }) async {
    final baseUrl = AppEnv.separationServerUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$baseUrl/separate');
    appLog.d('🔍 Sending audio to local Demucs server…');

    final request = http.MultipartRequest('POST', uri)
      ..fields['target'] = _targetField(target)
      ..files.add(
        await http.MultipartFile.fromPath(
          'audio',
          wavPath,
          filename: 'input.wav',
        ),
      );

    final streamedResponse =
        await _client.send(request).timeout(_requestTimeout);
    final body = await streamedResponse.stream.toBytes();

    if (streamedResponse.statusCode < 200 ||
        streamedResponse.statusCode >= 300) {
      throw AppException(
        messageKey: 'separationFailed',
        cause:
            'Local server failed (${streamedResponse.statusCode}): ${String.fromCharCodes(body.take(240))}',
      );
    }

    if (body.isEmpty) {
      throw const AppException(
        messageKey: 'separationFailed',
        cause: 'Local server returned an empty response',
      );
    }

    return body;
  }

  String _targetField(SeparationTarget target) {
    return switch (target) {
      SeparationTarget.vocals => 'vocals',
      SeparationTarget.instrumental => 'instrumental',
    };
  }
}
