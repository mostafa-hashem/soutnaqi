import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:soutnaqi/features/shell/cubit/shell_state.dart';
import 'package:soutnaqi/features/shell/cubit/shell_tab.dart';

class ShellCubit extends Cubit<ShellState> {
  ShellCubit() : super(const ShellState(selectedTab: ShellTab.workspace));

  void selectTab(ShellTab tab) {
    if (state.selectedTab == tab) return;
    emit(state.copyWith(selectedTab: tab));
  }
}
