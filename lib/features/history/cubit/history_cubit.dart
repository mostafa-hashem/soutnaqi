import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:soutnaqi/core/errors/app_exception.dart';
import 'package:soutnaqi/core/logging/app_log.dart';
import 'package:soutnaqi/features/history/cubit/history_state.dart';
import 'package:soutnaqi/features/history/data/models/project_record.dart';
import 'package:soutnaqi/features/history/data/project_history_repository.dart';

class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit({required ProjectHistoryRepository repository})
      : _repository = repository,
        super(const HistoryState());

  final ProjectHistoryRepository _repository;

  Future<void> loadProjects() async {
    appLog.d('🔍 Loading history…');
    emit(state.copyWith(status: HistoryStatus.loading));

    try {
      final projects = await _repository.fetchProjects();
      emit(
        HistoryState(
          status: HistoryStatus.loaded,
          projects: projects,
        ),
      );
    } on AppException {
      emit(state.copyWith(status: HistoryStatus.failure));
    } catch (error) {
      appLog.e('❌ History load failed', error: error);
      emit(state.copyWith(status: HistoryStatus.failure));
    }
  }

  Future<void> deleteProject(String projectId) async {
    emit(state.copyWith(deletingProjectId: projectId));
    try {
      await _repository.deleteProject(projectId: projectId);
      emit(
        state.copyWith(
          projects: state.projects.where((p) => p.id != projectId).toList(),
          clearDeleting: true,
        ),
      );
    } on AppException {
      emit(state.copyWith(clearDeleting: true));
      rethrow;
    } catch (error) {
      emit(state.copyWith(clearDeleting: true));
      throw AppException(messageKey: 'historyDeleteFailed', cause: error);
    }
  }

  void addProjectLocally(ProjectRecord project) {
    if (state.status != HistoryStatus.loaded) return;
    emit(
      state.copyWith(
        projects: [project, ...state.projects],
      ),
    );
  }
}
