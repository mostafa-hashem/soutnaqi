import 'package:equatable/equatable.dart';

enum OnDeviceModelStatus {
  checking,
  notDownloaded,
  downloading,
  ready,
  error,
}

class OnDeviceModelState extends Equatable {
  const OnDeviceModelState({
    this.status = OnDeviceModelStatus.checking,
    this.downloadProgress = 0,
    this.cachedSizeBytes = 0,
    this.errorMessageKey,
  });

  final OnDeviceModelStatus status;

  /// 0.0–1.0 while [status] is [OnDeviceModelStatus.downloading].
  final double downloadProgress;

  /// Populated once [status] is [OnDeviceModelStatus.ready].
  final int cachedSizeBytes;

  /// An [AppException.messageKey] to resolve via [appExceptionMessage] when
  /// [status] is [OnDeviceModelStatus.error].
  final String? errorMessageKey;

  OnDeviceModelState copyWith({
    OnDeviceModelStatus? status,
    double? downloadProgress,
    int? cachedSizeBytes,
    String? errorMessageKey,
  }) {
    return OnDeviceModelState(
      status: status ?? this.status,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      cachedSizeBytes: cachedSizeBytes ?? this.cachedSizeBytes,
      errorMessageKey: errorMessageKey ?? this.errorMessageKey,
    );
  }

  @override
  List<Object?> get props => [
        status,
        downloadProgress,
        cachedSizeBytes,
        errorMessageKey,
      ];
}
