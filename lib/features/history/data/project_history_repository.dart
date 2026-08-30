import 'dart:convert';

import 'package:soutnaqi/core/errors/app_exception.dart';
import 'package:soutnaqi/core/logging/app_log.dart';
import 'package:soutnaqi/core/storage/preferences_store.dart';
import 'package:soutnaqi/features/history/data/models/project_record.dart';
import 'package:soutnaqi/features/history/data/project_history_files_stub.dart'
    if (dart.library.io) 'package:soutnaqi/features/history/data/project_history_files_io.dart';
import 'package:uuid/uuid.dart';

class ProjectHistoryRepository {
  ProjectHistoryRepository({PreferencesStore? store})
      : _store = store ?? PreferencesStore.instance;

  final PreferencesStore _store;

  static const _storageKey = 'project_history';
  static const _uuid = Uuid();

  Future<List<ProjectRecord>> fetchProjects() async {
    appLog.d('🔍 Fetching project history…');

    try {
      final records = await _loadRecords();
      records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      appLog.d('✅ Loaded ${records.length} projects');
      return records;
    } catch (error) {
      appLog.e('❌ Failed to fetch projects', error: error);
      throw AppException(messageKey: 'historyLoadFailed', cause: error);
    }
  }

  Future<ProjectRecord> saveProject({
    required String localPath,
    required String fileName,
    required ProjectMediaType mediaType,
    String? operation,
  }) async {
    appLog.d('⚡ Saving project record…');

    try {
      final filePath = await copyProjectFile(
        sourcePath: localPath,
        fileName: fileName,
      );
      final record = ProjectRecord(
        id: _uuid.v4(),
        fileName: fileName,
        mediaType: mediaType,
        filePath: filePath,
        createdAt: DateTime.now().toUtc(),
        operation: operation,
      );

      final records = await _loadRecords();
      records.insert(0, record);
      await _persist(records);

      appLog.d('✅ Project record saved');
      return record;
    } on AppException {
      rethrow;
    } catch (error) {
      appLog.e('❌ Failed to save project', error: error);
      throw AppException(messageKey: 'historySaveFailed', cause: error);
    }
  }

  Future<void> deleteProject({required String projectId}) async {
    appLog.d('⚡ Deleting project record…');

    try {
      final records = await _loadRecords();
      final index = records.indexWhere((record) => record.id == projectId);
      if (index == -1) {
        throw const AppException(messageKey: 'historyDeleteFailed');
      }

      final record = records.removeAt(index);
      await deleteProjectFile(record.filePath);
      await _persist(records);
      appLog.d('✅ Project deleted');
    } on AppException {
      rethrow;
    } catch (error) {
      appLog.e('❌ Failed to delete project', error: error);
      throw AppException(messageKey: 'historyDeleteFailed', cause: error);
    }
  }

  Future<List<ProjectRecord>> _loadRecords() async {
    final preferences = await _store.preferences;
    final raw = preferences.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((row) => ProjectRecord.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> _persist(List<ProjectRecord> records) async {
    final preferences = await _store.preferences;
    await preferences.setString(
      _storageKey,
      jsonEncode(records.map((record) => record.toJson()).toList()),
    );
  }
}
