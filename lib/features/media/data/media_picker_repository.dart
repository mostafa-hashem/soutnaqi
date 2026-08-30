import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:soutnaqi/core/errors/app_exception.dart';
import 'package:soutnaqi/core/logging/app_log.dart';
import 'package:soutnaqi/features/media/data/models/media_file.dart';

class MediaPickerRepository {
  static const _audioExtensions = [
    'mp3',
    'wav',
    'm4a',
    'aac',
    'ogg',
    'flac',
    'opus',
    'wma',
  ];

  static const _videoExtensions = [
    'mp4',
    'mov',
    'mkv',
    'webm',
    'avi',
    'm4v',
    '3gp',
  ];

  Future<MediaFile?> pickAudio() => _pick(
        type: FileType.custom,
        allowedExtensions: _audioExtensions,
        expectedKind: MediaKind.audio,
      );

  /// Opens the system file picker filtered to common video formats.
  Future<MediaFile?> pickVideo() => _pick(
        type: FileType.custom,
        allowedExtensions: _videoExtensions,
        expectedKind: MediaKind.video,
      );

  Future<MediaFile> parseDroppedFile(XFile file) async {
    appLog.d('🔍 Parsing dropped file…');
    try {
      final kind = _kindFromName(file.name);
      if (kind == MediaKind.unknown) {
        throw const AppException(messageKey: 'mediaPickFailed');
      }

      final bytes = kIsWeb ? await file.readAsBytes() : null;
      final path = kIsWeb ? null : file.path;

      if (!kIsWeb && (path == null || path.isEmpty)) {
        throw const AppException(messageKey: 'mediaPickFailed');
      }

      return MediaFile(
        name: file.name,
        kind: kind,
        mimeType: lookupMimeType(file.name) ?? _fallbackMime(kind),
        sizeBytes: bytes?.length ?? await file.length(),
        path: path,
        bytes: bytes,
      );
    } on AppException {
      rethrow;
    } catch (error) {
      appLog.e('❌ Drop parse failed', error: error);
      throw AppException(messageKey: 'mediaPickFailed', cause: error);
    }
  }

  Future<MediaFile?> _pick({
    required FileType type,
    required MediaKind expectedKind,
    List<String>? allowedExtensions,
  }) async {
    appLog.d('🔍 Opening media picker…');
    try {
      final result = await FilePicker.platform.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
        withData: kIsWeb,
      );

      if (result == null || result.files.isEmpty) {
        appLog.d('⚡ Media picker cancelled');
        return null;
      }

      final file = result.files.single;
      if (file.name.isEmpty) {
        throw const AppException(messageKey: 'mediaPickFailed');
      }

      if (!kIsWeb && (file.path == null || file.path!.isEmpty)) {
        throw const AppException(messageKey: 'mediaPickFailed');
      }

      if (kIsWeb && (file.bytes == null || file.bytes!.isEmpty)) {
        throw const AppException(messageKey: 'mediaPickFailed');
      }

      final kind = _kindFromName(file.name);
      if (kind != expectedKind) {
        throw const AppException(messageKey: 'mediaPickFailed');
      }

      final mimeType = lookupMimeType(file.name) ?? _fallbackMime(expectedKind);
      final media = MediaFile(
        name: file.name,
        kind: expectedKind,
        mimeType: mimeType,
        sizeBytes: file.size,
        path: file.path,
        bytes: file.bytes,
      );

      appLog.d('✅ Media picked: ${media.name}');
      return media;
    } on AppException {
      rethrow;
    } catch (error) {
      appLog.e('❌ Media pick failed', error: error);
      throw AppException(messageKey: 'mediaPickFailed', cause: error);
    }
  }

  MediaKind _kindFromName(String name) {
    final mime = lookupMimeType(name);
    if (mime != null) {
      if (mime.startsWith('audio/')) return MediaKind.audio;
      if (mime.startsWith('video/')) return MediaKind.video;
    }

    final lower = name.toLowerCase();
    for (final ext in _audioExtensions) {
      if (lower.endsWith('.$ext')) return MediaKind.audio;
    }
    for (final ext in _videoExtensions) {
      if (lower.endsWith('.$ext')) return MediaKind.video;
    }
    return MediaKind.unknown;
  }

  String _fallbackMime(MediaKind kind) {
    return switch (kind) {
      MediaKind.audio => 'audio/mpeg',
      MediaKind.video => 'video/mp4',
      MediaKind.unknown => 'application/octet-stream',
    };
  }
}
