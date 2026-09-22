import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:soutnaqi/core/errors/app_exception.dart';
import 'package:soutnaqi/core/logging/app_log.dart';
import 'package:soutnaqi/features/separation/data/on_device/on_device_model_spec.dart';

/// Downloads and caches the on-device separation model. The model is fetched
/// once, from a static file host (not a compute server), into persistent
/// app-support storage — every separation run after that is fully offline.
class OnDeviceModelRepository {
  OnDeviceModelRepository();

  /// Dedicated client for the in-flight download so [cancelDownload] can
  /// abort the HTTP stream without affecting other callers.
  http.Client? _downloadClient;
  bool _cancelRequested = false;

  /// Aborts an in-progress [ensureModelDownloaded]. Safe to call when idle.
  void cancelDownload() {
    _cancelRequested = true;
    final client = _downloadClient;
    _downloadClient = null;
    client?.close();
  }

  Future<Directory> _modelDirectory() async {
    final supportDir = await getApplicationSupportDirectory();
    final dir = Directory(p.join(supportDir.path, 'models'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> _modelFile() async {
    final dir = await _modelDirectory();
    return File(p.join(dir.path, OnDeviceModelSpec.modelFileName));
  }

  Future<File> _partFile() async {
    final dir = await _modelDirectory();
    return File(p.join(dir.path, '${OnDeviceModelSpec.modelFileName}.part'));
  }

  /// Whether a verified copy of the model is already cached on disk. Only
  /// checks file size, not a full re-hash, to stay fast on every app
  /// launch — the checksum is verified once, right after download.
  Future<bool> isModelCached() async {
    final file = await _modelFile();
    if (!await file.exists()) return false;
    final size = await file.length();
    return size == OnDeviceModelSpec.expectedSizeBytes;
  }

  Future<int> cachedModelSizeBytes() async {
    final file = await _modelFile();
    if (!await file.exists()) return 0;
    return file.length();
  }

  Future<String> modelPath() async => (await _modelFile()).path;

  /// Downloads the model if it isn't already cached, verifying its
  /// checksum. Safe to call before every separation — a no-op once cached.
  /// Throws [AppException] with `onDeviceModelDownloadCancelled` when the
  /// user aborts via [cancelDownload].
  Future<void> ensureModelDownloaded({
    void Function(double progress)? onProgress,
  }) async {
    if (await isModelCached()) return;

    final partFile = await _partFile();
    final targetFile = await _modelFile();
    IOSink? sink;
    var completed = false;
    _cancelRequested = false;
    final downloadClient = http.Client();
    _downloadClient = downloadClient;
    try {
      final response = await downloadClient.send(
        http.Request('GET', Uri.parse(OnDeviceModelSpec.downloadUrl)),
      );
      if (_cancelRequested) {
        throw const AppException(
          messageKey: 'onDeviceModelDownloadCancelled',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AppException(
          messageKey: 'onDeviceModelDownloadFailed',
          type: AppExceptionType.network,
          cause: 'Download failed (${response.statusCode})',
        );
      }

      final total =
          response.contentLength ?? OnDeviceModelSpec.expectedSizeBytes;
      var received = 0;
      Digest? digest;
      final digestInput = sha256.startChunkedConversion(
        _CapturingSink((d) => digest = d),
      );
      sink = partFile.openWrite();

      await for (final chunk in response.stream) {
        if (_cancelRequested) {
          throw const AppException(
            messageKey: 'onDeviceModelDownloadCancelled',
          );
        }
        sink.add(chunk);
        digestInput.add(chunk);
        received += chunk.length;
        if (total > 0) onProgress?.call(received / total);
      }
      await sink.flush();
      await sink.close();
      sink = null;
      digestInput.close();
      final actualSha256 = digest.toString();

      if (received != OnDeviceModelSpec.expectedSizeBytes ||
          actualSha256 != OnDeviceModelSpec.expectedSha256) {
        throw const AppException(
          messageKey: 'onDeviceModelCorrupted',
          type: AppExceptionType.validation,
        );
      }

      await partFile.rename(targetFile.path);
      completed = true;
    } on AppException {
      rethrow;
    } on SocketException catch (error) {
      if (_cancelRequested) {
        throw const AppException(
          messageKey: 'onDeviceModelDownloadCancelled',
        );
      }
      appLog.e('❌ On-device model download failed', error: error);
      throw AppException(
        messageKey: 'onDeviceModelDownloadFailed',
        type: AppExceptionType.network,
        cause: error,
      );
    } on FileSystemException catch (error) {
      appLog.e('❌ On-device model storage error', error: error);
      throw AppException(
        messageKey: 'onDeviceInsufficientStorage',
        type: AppExceptionType.validation,
        cause: error,
      );
    } catch (error) {
      if (_cancelRequested) {
        throw const AppException(
          messageKey: 'onDeviceModelDownloadCancelled',
        );
      }
      appLog.e('❌ On-device model download failed', error: error);
      throw AppException(
        messageKey: 'onDeviceModelDownloadFailed',
        type: AppExceptionType.network,
        cause: error,
      );
    } finally {
      if (identical(_downloadClient, downloadClient)) {
        _downloadClient = null;
      }
      downloadClient.close();
      if (sink != null) {
        await sink.close();
      }
      if (!completed && await partFile.exists()) {
        try {
          await partFile.delete();
        } catch (_) {}
      }
    }
  }

  Future<void> deleteCachedModel() async {
    final file = await _modelFile();
    if (await file.exists()) {
      await file.delete();
    }
  }
}

/// Captures the single [Digest] a chunked hash conversion emits, without
/// pulling in `package:convert` just for `AccumulatorSink`.
class _CapturingSink implements Sink<Digest> {
  _CapturingSink(this._onDigest);

  final void Function(Digest) _onDigest;

  @override
  void add(Digest data) => _onDigest(data);

  @override
  void close() {}
}
