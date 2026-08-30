import 'package:equatable/equatable.dart';

import 'package:soutnaqi/features/shell/cubit/shell_tab.dart';

class ShellState extends Equatable {
  const ShellState({required this.selectedTab});

  final ShellTab selectedTab;

  ShellState copyWith({ShellTab? selectedTab}) {
    return ShellState(selectedTab: selectedTab ?? this.selectedTab);
  }

  @override
  List<Object?> get props => [selectedTab];
}
