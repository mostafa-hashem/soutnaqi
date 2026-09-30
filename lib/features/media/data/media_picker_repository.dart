import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:soutnaqi/core/errors/app_exception.dart';
import 'package:soutnaqi/core/logging/app_log.dart';
import 'package:soutnaqi/features/media/data/models/media_file.dart';

class MediaPickerRepository {
  MediaPickerRepository({ImagePicker? imagePicker})
      : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

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
        type: FileType.audio,
        expectedKind: MediaKind.audio,
      );

  /// Opens the system gallery/photos picker to select a video.
  Future<MediaFile?> pickVideo() async {
    appLog.d('🔍 Opening video gallery picker…');
    try {
      final file = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
      );

      if (file == null) {
        appLog.d('⚡ Video picker cancelled');
        return null;
      }

      if (file.name.isEmpty) {
        throw const AppException(messageKey: 'mediaPickFailed');
      }

      final bytes = kIsWeb ? await file.readAsBytes() : null;
      final path = kIsWeb ? null : file.path;

      if (!kIsWeb && (path == null || path.isEmpty)) {
        throw const AppException(messageKey: 'mediaPickFailed');
      }

      if (kIsWeb && (bytes == null || bytes.isEmpty)) {
        throw const AppException(messageKey: 'mediaPickFailed');
      }

      final sizeBytes = bytes?.length ?? await file.length();
      final mimeType = lookupMimeType(file.name) ??
          (path != null ? lookupMimeType(path) : null) ??
          _fallbackMime(MediaKind.video);

      final media = MediaFile(
        name: file.name,
        kind: MediaKind.video,
        mimeType: mimeType,
        sizeBytes: sizeBytes,
        path: path,
        bytes: bytes,
      );

      appLog.d('✅ Video picked from gallery: ${media.name}');
      return media;
    } on AppException {
      rethrow;
    } catch (error) {
      appLog.e('❌ Video pick failed', error: error);
      throw AppException(messageKey: 'mediaPickFailed', cause: error);
    }
  }

  Future<MediaFile> parseDroppedFile(XFile file) async {
    appLog.d('🔍 Parsing dropped file…');
    try {
      var kind = _kindFromName(file.name);
      if (kind == MediaKind.unknown && file.path.isNotEmpty) {
        kind = _kindFromName(file.path);
      }
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

  Future<MediaFile> parseLocalFilePath(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw const AppException(messageKey: 'mediaPickFailed');
    }
    final name = p.basename(filePath);
    var kind = _kindFromName(name);
    if (kind == MediaKind.unknown) {
      final mime = lookupMimeType(filePath);
      if (mime != null && mime.startsWith('video/')) {
        kind = MediaKind.video;
      } else {
        kind = MediaKind.audio;
      }
    }
    final sizeBytes = await file.length();
    final mimeType = lookupMimeType(filePath) ?? _fallbackMime(kind);
    return MediaFile(
      name: name,
      kind: kind,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      path: filePath,
    );
  }

  Future<MediaFile?> _pick({
    required FileType type,
    required MediaKind expectedKind,
    List<String>? allowedExtensions,
  }) async {
    appLog.d('🔍 Opening media picker: type=$type…');
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

      var kind = _kindFromName(file.name);
      if (kind == MediaKind.unknown && file.extension != null) {
        kind = _kindFromName('.${file.extension!}');
      }
      if (kind == MediaKind.unknown && file.path != null) {
        kind = _kindFromName(file.path!);
      }
      if (kind == MediaKind.unknown) {
        kind = expectedKind;
      }

      if (kind != expectedKind) {
        throw const AppException(messageKey: 'mediaPickFailed');
      }

      final mimeType = lookupMimeType(file.name) ??
          (file.path != null ? lookupMimeType(file.path!) : null) ??
          _fallbackMime(expectedKind);
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
