import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min/return_code.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:soutnaqi/core/config/app_env.dart';
import 'package:soutnaqi/core/errors/app_exception.dart';
import 'package:soutnaqi/core/logging/app_log.dart';
import 'package:soutnaqi/features/separation/data/separation_audio_io.dart';
import 'package:soutnaqi/features/separation/data/separation_progress.dart';
import 'package:soutnaqi/features/separation/data/separation_service.dart';
import 'package:soutnaqi/features/separation/data/separation_target.dart';
import 'package:uuid/uuid.dart';

SeparationService createPlatformSeparationService() =>
    ReplicateSeparationService();

class ReplicateSeparationService implements SeparationService {
  ReplicateSeparationService({http.Client? client})
      : _client = client ?? http.Client();

  static const _uuid = Uuid();
  static const _modelVersion =
      'd5de8c46b626a46ba6258f685454750c54197420435f9990846fd27a2e2dfa5f';
  static const _pollInterval = Duration(seconds: 3);
  static const _maxPollAttempts = 300;
  static const _requestTimeout = Duration(seconds: 60);
  static const _uploadTimeout = Duration(minutes: 5);

  final http.Client _client;

  @override
  bool get isSupported => AppEnv.isReplicateSeparationConfigured;

  @override
  Future<String> separate({
    required String inputAudioPath,
    required SeparationTarget target,
    SeparationProgressCallback? onProgress,
  }) async {
    if (!isSupported) {
      throw const AppException(messageKey: 'separationNotConfigured');
    }

    appLog.d('⚡ Starting AI stem separation: $target');
    var preparedPath = inputAudioPath;
    try {
      onProgress?.call(
        const SeparationProgress(stage: SeparationStage.preparingAudio),
      );
      preparedPath = await SeparationAudioIo.prepareWavInput(inputAudioPath);
      onProgress?.call(
        const SeparationProgress(stage: SeparationStage.separating),
      );
      final uploadedUrl = await _uploadAudio(preparedPath);
      final output = await _createAndAwaitPrediction(uploadedUrl);
      appLog.d('🔍 Demucs output keys: ${output.keys.join(', ')}');
      onProgress?.call(
        const SeparationProgress(stage: SeparationStage.encodingOutput),
      );
      final wavPath = await switch (target) {
        SeparationTarget.vocals => _downloadResolvedStem(
            output: output,
            keys: const ['vocals', 'vocals.wav'],
          ),
        SeparationTarget.instrumental => _resolveInstrumentalWav(output),
      };
      final outputPath = await SeparationAudioIo.encodeWavToM4a(wavPath);
      appLog.d('✅ AI separation complete: $outputPath');
      return outputPath;
    } on AppException {
      rethrow;
    } on TimeoutException catch (error) {
      appLog.e('❌ Separation request timed out', error: error);
      throw AppException(messageKey: 'separationTimeout', cause: error);
    } on SocketException catch (error) {
      appLog.e('❌ Separation network error', error: error);
      throw AppException(
        messageKey: 'networkError',
        type: AppExceptionType.network,
        cause: error,
      );
    } catch (error) {
      appLog.e('❌ Separation failed', error: error);
      throw AppException(messageKey: 'separationFailed', cause: error);
    } finally {
      if (preparedPath != inputAudioPath) {
        try {
          await File(preparedPath).delete();
        } catch (_) {}
      }
    }
  }

  Future<String> _uploadAudio(String localPath) async {
    appLog.d('🔍 Uploading audio for separation…');
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.replicate.com/v1/files'),
    );
    request.headers['Authorization'] = 'Bearer ${AppEnv.replicateApiToken}';
    request.files.add(
      await http.MultipartFile.fromPath(
        'content',
        localPath,
        filename: p.basename(localPath),
      ),
    );

    final streamedResponse = await _client.send(request).timeout(_uploadTimeout);
    final body = await streamedResponse.stream.bytesToString();
    if (streamedResponse.statusCode < 200 ||
        streamedResponse.statusCode >= 300) {
      throw AppException(
        messageKey: 'separationFailed',
        cause: 'Upload failed (${streamedResponse.statusCode}): $body',
      );
    }

    final json = jsonDecode(body) as Map<String, dynamic>;
    final urls = json['urls'] as Map<String, dynamic>?;
    final url = urls?['get'] as String?;
    if (url != null && url.isNotEmpty) {
      appLog.d('✅ Audio uploaded for separation');
      return url;
    }

    final fileId = json['id'] as String?;
    if (fileId != null && fileId.isNotEmpty) {
      appLog.d('✅ Audio uploaded for separation (file: $fileId)');
      return 'https://api.replicate.com/v1/files/$fileId';
    }

    throw const AppException(
      messageKey: 'separationFailed',
      cause: 'Upload response missing file URL',
    );
  }

  Future<Map<String, dynamic>> _createAndAwaitPrediction(String audioUrl) async {
    appLog.d('🔍 Creating Demucs prediction…');
    final response = await _client.post(
      Uri.parse('https://api.replicate.com/v1/predictions'),
      headers: {
        'Authorization': 'Bearer ${AppEnv.replicateApiToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'version': _modelVersion,
        'input': {
          'audio': audioUrl,
          'model': 'htdemucs_ft',
          // vocals returns both vocals + no_vocals (accompaniment).
          'stem': 'vocals',
          'shifts': 1,
        },
      }),
    );

    appLog.d(
      '🔍 Create response ${response.statusCode}: ${_truncate(response.body)}',
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwApiError(response.statusCode, response.body);
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final id = json['id'] as String?;
    final status = json['status'] as String? ?? 'unknown';
    if (id == null || id.isEmpty) {
      throw const AppException(
        messageKey: 'separationFailed',
        cause: 'Prediction response missing id',
      );
    }

    appLog.d('🔍 Prediction created: $id (status: $status)');

    if (status == 'succeeded') {
      return _normalizeOutput(json['output']);
    }

    if (status == 'failed' || status == 'canceled') {
      throw AppException(
        messageKey: 'separationFailed',
        cause: json['error'] ?? status,
      );
    }

    return _waitForOutput(id);
  }

  String _truncate(String value, {int maxLength = 240}) {
    if (value.length <= maxLength) {
      return value;
    }
    return '${value.substring(0, maxLength)}…';
  }

  Future<Map<String, dynamic>> _waitForOutput(String predictionId) async {
    appLog.d('🔍 Waiting for Demucs result…');
    for (var attempt = 0; attempt < _maxPollAttempts; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(_pollInterval);
      }

      http.Response response;
      try {
        response = await _client
            .get(
              Uri.parse(
                'https://api.replicate.com/v1/predictions/$predictionId',
              ),
              headers: {'Authorization': 'Bearer ${AppEnv.replicateApiToken}'},
            )
            .timeout(_requestTimeout);
      } on TimeoutException {
        appLog.d('🔍 Poll request timed out, retrying…');
        continue;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _throwApiError(
          response.statusCode,
          response.body,
          context: 'Poll failed',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final status = json['status'] as String? ?? '';

      if (attempt == 0 || attempt.isEven) {
        appLog.d('🔍 Demucs status: $status (attempt ${attempt + 1})');
      }

      if (status == 'succeeded') {
        return _normalizeOutput(json['output']);
      }

      if (status == 'failed' || status == 'canceled') {
        final error = json['error'] ?? status;
        appLog.e('❌ Demucs prediction failed', error: error);
        throw AppException(
          messageKey: 'separationFailed',
          cause: error,
        );
      }
    }

    throw const AppException(messageKey: 'separationTimeout');
  }

  Map<String, dynamic> _normalizeOutput(Object? output) {
    if (output is Map<String, dynamic>) {
      return output;
    }
    if (output is Map) {
      return Map<String, dynamic>.from(output);
    }
    if (output is String && output.isNotEmpty) {
      final decoded = jsonDecode(output);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    }

    throw AppException(
      messageKey: 'separationFailed',
      cause: 'Unexpected output format: $output',
    );
  }

  Future<String> _resolveInstrumentalWav(Map<String, dynamic> output) async {
    final noVocalsUrl = _findStemUrl(
      output: output,
      keys: const ['no_vocals', 'no_vocals.wav', 'accompaniment'],
    );
    if (noVocalsUrl != null) {
      appLog.d('🔍 Using no_vocals stem');
      return await _downloadStem(noVocalsUrl);
    }

    appLog.d('🔍 Mixing drums + bass + other stems');
    return _mixInstrumentalStems(output);
  }

  Future<String> _downloadResolvedStem({
    required Map<String, dynamic> output,
    required List<String> keys,
  }) async {
    final url = _findStemUrl(output: output, keys: keys);
    if (url == null) {
      throw AppException(
        messageKey: 'separationFailed',
        cause: 'Stem not found in output: ${output.keys.join(', ')}',
      );
    }
    return await _downloadStem(url);
  }

  String? _findStemUrl({
    required Map<String, dynamic> output,
    required List<String> keys,
  }) {
    for (final key in keys) {
      final url = _extractUrl(output[key]);
      if (url != null) {
        return url;
      }
    }

    for (final entry in output.entries) {
      final normalizedKey = entry.key.toLowerCase();
      for (final key in keys) {
        if (normalizedKey == key.toLowerCase() ||
            normalizedKey == '${key.toLowerCase()}.wav') {
          final url = _extractUrl(entry.value);
          if (url != null) {
            return url;
          }
        }
      }
    }

    return null;
  }

  String? _extractUrl(Object? value) {
    if (value is String && value.isNotEmpty) {
      return value;
    }
    if (value is Map) {
      for (final key in ['url', 'href', 'uri']) {
        final nested = value[key];
        if (nested is String && nested.isNotEmpty) {
          return nested;
        }
      }
    }
    return null;
  }

  Future<String> _mixInstrumentalStems(Map<String, dynamic> output) async {
    const stemNames = ['drums', 'bass', 'other'];
    final localPaths = <String>[];

    for (final name in stemNames) {
      final url = _findStemUrl(
        output: output,
        keys: [name, '$name.wav'],
      );
      if (url == null) {
        continue;
      }
      localPaths.add(await _downloadStem(url, suffix: name));
    }

    if (localPaths.isEmpty) {
      throw AppException(
        messageKey: 'separationFailed',
        cause: 'Instrumental stems not found in: ${output.keys.join(', ')}',
      );
    }

    if (localPaths.length == 1) {
      return localPaths.first;
    }

    final directory = await getTemporaryDirectory();
    final outputPath = '${directory.path}/soutnaqi_${_uuid.v4()}.wav';
    final inputs = localPaths.map((path) => '-i "$path"').join(' ');
    final filter =
        'amix=inputs=${localPaths.length}:duration=longest:dropout_transition=0';
    final command =
        '-y $inputs -filter_complex "$filter" -c:a pcm_s16le "$outputPath"';
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    for (final path in localPaths) {
      try {
        await File(path).delete();
      } catch (_) {}
    }

    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getAllLogsAsString();
      throw AppException(messageKey: 'separationFailed', cause: logs);
    }

    return outputPath;
  }

  Future<String> _downloadStem(String url, {String? suffix}) async {
    appLog.d(
      '🔍 Downloading separated stem${suffix == null ? '' : ' ($suffix)'}…',
    );
    final response = await _client.get(Uri.parse(url)).timeout(_requestTimeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AppException(
        messageKey: 'separationFailed',
        cause: 'Download failed (${response.statusCode})',
      );
    }

    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/soutnaqi_${_uuid.v4()}.wav';
    await File(path).writeAsBytes(response.bodyBytes);
    return path;
  }

  Never _throwApiError(
    int statusCode,
    String body, {
    String context = 'Prediction failed',
  }) {
    if (statusCode == 402) {
      throw const AppException(messageKey: 'separationInsufficientCredit');
    }
    throw AppException(
      messageKey: 'separationFailed',
      cause: '$context ($statusCode): $body',
    );
  }
}
