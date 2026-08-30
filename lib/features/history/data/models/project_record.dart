import 'package:equatable/equatable.dart';

enum ProjectMediaType { audio, video }

class ProjectRecord extends Equatable {
  const ProjectRecord({
    required this.id,
    required this.fileName,
    required this.mediaType,
    required this.filePath,
    required this.createdAt,
    this.operation,
  });

  final String id;
  final String fileName;
  final ProjectMediaType mediaType;
  final String filePath;
  final String? operation;
  final DateTime createdAt;

  factory ProjectRecord.fromJson(Map<String, dynamic> json) {
    return ProjectRecord(
      id: json['id'] as String,
      fileName: json['file_name'] as String,
      mediaType: (json['media_type'] as String) == 'video'
          ? ProjectMediaType.video
          : ProjectMediaType.audio,
      filePath: json['file_path'] as String,
      operation: json['operation'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file_name': fileName,
      'media_type': mediaType == ProjectMediaType.video ? 'video' : 'audio',
      'file_path': filePath,
      'operation': operation,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        fileName,
        mediaType,
        filePath,
        operation,
        createdAt,
      ];
}
