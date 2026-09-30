import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soutnaqi/core/errors/app_exception.dart';
import 'package:soutnaqi/core/logging/app_log.dart';
import 'package:soutnaqi/features/separation/cubit/on_device_model_state.dart';
import 'package:soutnaqi/features/separation/data/on_device/on_device_model_repository.dart';
import 'package:soutnaqi/features/separation/data/separation_platform.dart';

/// Drives the "on-device model" row in Settings — lets a user check
/// whether the separation model is cached, download it ahead of time, or
/// delete it to free up space. Independent of [SeparationService]: a
/// separation run downloads the model itself if this was never opened.
class OnDeviceModelCubit extends Cubit<OnDeviceModelState> {
  OnDeviceModelCubit({OnDeviceModelRepository? repository})
      : _repository = repository ?? OnDeviceModelRepository(),
        super(const OnDeviceModelState()) {
    if (_repository.isDownloading) {
      emit(
        state.copyWith(
          status: OnDeviceModelStatus.downloading,
          downloadProgress: _repository.currentDownloadProgress,
        ),
      );
    }
    _repository.addProgressListener(_onRepositoryProgress);
  }

  final OnDeviceModelRepository _repository;

  bool get isDownloading =>
      _repository.isDownloading ||
      state.status == OnDeviceModelStatus.downloading;

  void _onRepositoryProgress(double progress) {
    if (isClosed) return;
    if (state.status == OnDeviceModelStatus.downloading) {
      emit(state.copyWith(downloadProgress: progress));
    }
  }

  @override
  Future<void> close() {
    _repository.removeProgressListener(_onRepositoryProgress);
    return super.close();
  }

  Future<void> refresh() async {
    if (_repository.isDownloading) {
      emit(
        state.copyWith(
          status: OnDeviceModelStatus.downloading,
          downloadProgress: _repository.currentDownloadProgress,
        ),
      );
      return;
    }

    emit(state.copyWith(status: OnDeviceModelStatus.checking));
    try {
      if (await _repository.isModelCached()) {
        final size = await _repository.cachedModelSizeBytes();
        emit(
          OnDeviceModelState(
            status: OnDeviceModelStatus.ready,
            cachedSizeBytes: size,
          ),
        );
        unawaited(warmUpSeparationIfReady());
      } else {
        emit(const OnDeviceModelState(status: OnDeviceModelStatus.notDownloaded));
      }
    } catch (error) {
      appLog.e('❌ On-device model status check failed', error: error);
      emit(
        const OnDeviceModelState(status: OnDeviceModelStatus.notDownloaded),
      );
    }
  }

  Future<void> download() async {
    if (_repository.isDownloading) {
      return;
    }

    emit(
      state.copyWith(
        status: OnDeviceModelStatus.downloading,
        downloadProgress: _repository.currentDownloadProgress,
      ),
    );
    try {
      await _repository.ensureModelDownloaded(
        onProgress: (progress) {
          if (isClosed) return;
          emit(state.copyWith(downloadProgress: progress));
        },
      );
      await refresh();
      unawaited(warmUpSeparationIfReady());
    } on AppException catch (error) {
      if (isClosed) return;
      if (error.messageKey == 'onDeviceModelDownloadCancelled') {
        appLog.d('🔍 On-device model download cancelled by user');
        emit(
          const OnDeviceModelState(status: OnDeviceModelStatus.notDownloaded),
        );
        return;
      }
      emit(
        state.copyWith(
          status: OnDeviceModelStatus.error,
          errorMessageKey: error.messageKey,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      appLog.e('❌ On-device model download failed', error: error);
      emit(
        state.copyWith(
          status: OnDeviceModelStatus.error,
          errorMessageKey: 'onDeviceModelDownloadFailed',
        ),
      );
    }
  }

  /// Stops an in-progress download and returns to [OnDeviceModelStatus.notDownloaded] immediately.
  void cancelDownload() {
    if (!_repository.isDownloading &&
        state.status != OnDeviceModelStatus.downloading) {
      return;
    }
    _repository.cancelDownload();
    emit(const OnDeviceModelState(status: OnDeviceModelStatus.notDownloaded));
  }

  Future<void> delete() async {
    try {
      await _repository.deleteCachedModel();
    } catch (error) {
      appLog.e('❌ On-device model delete failed', error: error);
    }
    await refresh();
  }
}
