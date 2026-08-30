import 'package:equatable/equatable.dart';

import 'package:soutnaqi/features/history/data/models/project_record.dart';

enum HistoryStatus { initial, loading, loaded, failure }

class HistoryState extends Equatable {
  const HistoryState({
    this.status = HistoryStatus.initial,
    this.projects = const [],
    this.deletingProjectId,
  });

  final HistoryStatus status;
  final List<ProjectRecord> projects;
  final String? deletingProjectId;

  bool get isLoading => status == HistoryStatus.loading;
  bool get isEmpty => projects.isEmpty && status == HistoryStatus.loaded;

  HistoryState copyWith({
    HistoryStatus? status,
    List<ProjectRecord>? projects,
    String? deletingProjectId,
    bool clearDeleting = false,
  }) {
    return HistoryState(
      status: status ?? this.status,
      projects: projects ?? this.projects,
      deletingProjectId:
          clearDeleting ? null : (deletingProjectId ?? this.deletingProjectId),
    );
  }

  @override
  List<Object?> get props => [status, projects, deletingProjectId];
}
