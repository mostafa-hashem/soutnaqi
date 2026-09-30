import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:soutnaqi/core/errors/app_exception.dart';
import 'package:soutnaqi/core/logging/app_log.dart';
import 'package:soutnaqi/core/services/background_task_service.dart';
import 'package:soutnaqi/features/separation/data/on_device/on_device_model_spec.dart';

/// Downloads and caches the on-device separation model. The model is fetched
/// once, from a static file host (not a compute server), into persistent
/// app-support storage — every separation run after that is fully offline.
///
/// Supports resumable HTTP downloads via Range headers, automatic retry with
/// backoff, background execution via WakeLock, and instant cancellation.
class OnDeviceModelRepository {
  factory OnDeviceModelRepository() => instance;

  OnDeviceModelRepository._();

  static final OnDeviceModelRepository instance = OnDeviceModelRepository._();

  http.Client? _downloadClient;
  StreamSubscription<List<int>>? _downloadSub;
  bool _cancelRequested = false;

  Future<void>? _activeDownloadFuture;
  final Set<void Function(double progress)> _progressListeners = {};
  double _lastReportedProgress = 0.0;

  bool get isDownloading => _activeDownloadFuture != null;
  double get currentDownloadProgress => _lastReportedProgress;

  void addProgressListener(void Function(double progress) listener) {
    _progressListeners.add(listener);
    if (_lastReportedProgress > 0) {
      listener(_lastReportedProgress);
    }
  }

  void removeProgressListener(void Function(double progress) listener) {
    _progressListeners.remove(listener);
  }

  void _notifyProgress(double progress) {
    for (final listener in List.of(_progressListeners)) {
      try {
        listener(progress);
      } catch (_) {}
    }
  }

  /// Aborts an in-progress [ensureModelDownloaded] immediately. Safe to call when idle.
  void cancelDownload() {
    _cancelRequested = true;
    _downloadSub?.cancel();
    _downloadSub = null;
    final client = _downloadClient;
    _downloadClient = null;
    client?.close();
    _activeDownloadFuture = null;
    _progressListeners.clear();
    _lastReportedProgress = 0.0;
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

  /// Whether a verified copy of the model is already cached on disk.
  Future<bool> isModelCached() async {
    await _deleteLegacyModel();
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

  /// Downloads the model with Range resume and retry support, keeping WakeLock active.
  /// If a download is already in flight, joins the active download without duplicating requests.
  Future<void> ensureModelDownloaded({
    void Function(double progress)? onProgress,
  }) async {
    if (await isModelCached()) return;

    if (onProgress != null) {
      _progressListeners.add(onProgress);
      if (_lastReportedProgress > 0) {
        onProgress(_lastReportedProgress);
      }
    }

    if (_activeDownloadFuture != null) {
      await _activeDownloadFuture!;
      return;
    }

    final future = _executeDownload();
    _activeDownloadFuture = future;

    try {
      await future;
    } finally {
      if (identical(_activeDownloadFuture, future)) {
        _activeDownloadFuture = null;
        _progressListeners.clear();
        _lastReportedProgress = 0.0;
      }
    }
  }

  Future<void> _executeDownload() async {
    final partFile = await _partFile();
    final targetFile = await _modelFile();
    var completed = false;
    _cancelRequested = false;

    await BackgroundTaskService.instance.acquireWakeLock();

    try {
      const maxRetries = 10;
      for (var attempt = 0; attempt < maxRetries; attempt++) {
        if (_cancelRequested) {
          throw const AppException(
            messageKey: 'onDeviceModelDownloadCancelled',
          );
        }

        var existingLength =
            await partFile.exists() ? await partFile.length() : 0;
        if (existingLength > OnDeviceModelSpec.expectedSizeBytes) {
          try {
            await partFile.delete();
          } catch (_) {}
          existingLength = 0;
        } else if (existingLength == OnDeviceModelSpec.expectedSizeBytes) {
          final isVerified = await _verifyAndFinalize(partFile, targetFile);
          if (isVerified) {
            completed = true;
            return;
          }
          existingLength = 0;
        }

        final initialProgress =
            (existingLength / OnDeviceModelSpec.expectedSizeBytes)
                .clamp(0.0, 1.0);
        if (initialProgress > _lastReportedProgress) {
          _lastReportedProgress = initialProgress;
          _notifyProgress(_lastReportedProgress);
        }

        http.Client? client;
        IOSink? sink;

        try {
          client = http.Client();
          _downloadClient = client;

          final request =
              http.Request('GET', Uri.parse(OnDeviceModelSpec.downloadUrl));
          if (existingLength > 0) {
            request.headers['Range'] = 'bytes=$existingLength-';
            appLog.d(
              '⚡ Resuming model download from $existingLength bytes (attempt ${attempt + 1})',
            );
          } else {
            appLog.d('⚡ Starting model download (attempt ${attempt + 1})');
          }

          final response = await client.send(request);
          if (_cancelRequested) {
            throw const AppException(
              messageKey: 'onDeviceModelDownloadCancelled',
            );
          }

          final isPartial = response.statusCode == 206;
          final isSuccess = response.statusCode == 200 || isPartial;

          if (!isSuccess) {
            if (response.statusCode == 416) {
              try {
                await partFile.delete();
              } catch (_) {}
              continue;
            }
            throw AppException(
              messageKey: 'onDeviceModelDownloadFailed',
              type: AppExceptionType.network,
              cause: 'Download failed (${response.statusCode})',
            );
          }

          if (!isPartial) {
            _lastReportedProgress = 0.0;
            _notifyProgress(0.0);
          }

          var received = isPartial ? existingLength : 0;
          sink = partFile.openWrite(
            mode: isPartial ? FileMode.append : FileMode.write,
          );

          final completer = Completer<void>();
          final sub = response.stream.listen(
            (chunk) {
              if (_cancelRequested) {
                _downloadSub?.cancel();
                _downloadSub = null;
                if (!completer.isCompleted) {
                  completer.completeError(
                    const AppException(
                      messageKey: 'onDeviceModelDownloadCancelled',
                    ),
                  );
                }
                return;
              }
              sink?.add(chunk);
              received += chunk.length;
              final rawProgress = (received / OnDeviceModelSpec.expectedSizeBytes)
                  .clamp(0.0, 1.0);
              if (rawProgress >= _lastReportedProgress) {
                _lastReportedProgress = rawProgress;
                _notifyProgress(_lastReportedProgress);
              }
            },
            onError: (Object error, [StackTrace? stackTrace]) {
              if (!completer.isCompleted) {
                completer.completeError(error, stackTrace);
              }
            },
            onDone: () {
              if (!completer.isCompleted) completer.complete();
            },
            cancelOnError: true,
          );
          _downloadSub = sub;

          await completer.future;
          await sink.flush();
          await sink.close();
          sink = null;

          final isVerified = await _verifyAndFinalize(partFile, targetFile);
          if (isVerified) {
            completed = true;
            return;
          } else {
            throw const AppException(
              messageKey: 'onDeviceModelCorrupted',
              type: AppExceptionType.validation,
            );
          }
        } on AppException {
          rethrow;
        } catch (error) {
          if (_cancelRequested) {
            throw const AppException(
              messageKey: 'onDeviceModelDownloadCancelled',
            );
          }
          appLog.w(
            '⚠️ Model download attempt ${attempt + 1} interrupted: $error',
          );
          if (attempt == maxRetries - 1) {
            appLog.e(
              '❌ On-device model download retries exhausted',
              error: error,
            );
            throw AppException(
              messageKey: 'onDeviceModelDownloadFailed',
              type: AppExceptionType.network,
              cause: error,
            );
          }
          await Future<void>.delayed(
            Duration(seconds: (attempt + 1).clamp(1, 4)),
          );
        } finally {
          _downloadSub?.cancel();
          _downloadSub = null;
          if (identical(_downloadClient, client)) {
            _downloadClient = null;
          }
          client?.close();
          if (sink != null) {
            try {
              await sink.close();
            } catch (_) {}
          }
        }
      }
    } finally {
      await BackgroundTaskService.instance.releaseWakeLock();
      if (!completed && _cancelRequested) {
        if (await partFile.exists()) {
          try {
            await partFile.delete();
          } catch (_) {}
        }
      }
    }
  }

  Future<bool> _verifyAndFinalize(File partFile, File targetFile) async {
    if (!await partFile.exists()) return false;
    final length = await partFile.length();
    if (length != OnDeviceModelSpec.expectedSizeBytes) return false;

    final digest = await sha256.bind(partFile.openRead()).first;
    if (digest.toString() != OnDeviceModelSpec.expectedSha256) {
      appLog.e('❌ Model checksum mismatch');
      try {
        await partFile.delete();
      } catch (_) {}
      return false;
    }

    await partFile.rename(targetFile.path);
    appLog.d('✅ Model downloaded and verified: ${targetFile.path}');
    return true;
  }

  Future<void> deleteCachedModel() async {
    final file = await _modelFile();
    if (await file.exists()) {
      await file.delete();
    }
    final part = await _partFile();
    if (await part.exists()) {
      await part.delete();
    }
  }

  /// The previous HTDemucs file is ~166 MB and is no longer used.
  Future<void> _deleteLegacyModel() async {
    final dir = await _modelDirectory();
    final legacy =
        File(p.join(dir.path, OnDeviceModelSpec.legacyModelFileName));
    if (await legacy.exists()) {
      appLog.d('🔍 Removing previous on-device model');
      await legacy.delete();
    }
  }
}
