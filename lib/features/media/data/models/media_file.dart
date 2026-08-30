import 'package:equatable/equatable.dart';

enum MediaKind { audio, video, unknown }

class MediaFile extends Equatable {
  const MediaFile({
    required this.name,
    required this.kind,
    required this.mimeType,
    required this.sizeBytes,
    this.path,
    this.bytes,
  });

  final String name;
  final MediaKind kind;
  final String mimeType;
  final int sizeBytes;
  final String? path;
  final List<int>? bytes;

  bool get isAudio => kind == MediaKind.audio;
  bool get isVideo => kind == MediaKind.video;
  bool get hasLocalPath => path != null && path!.isNotEmpty;

  @override
  List<Object?> get props => [name, kind, mimeType, sizeBytes, path];
}
