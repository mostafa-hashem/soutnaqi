import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soutnaqi/features/settings/cubit/settings_cubit.dart';
import 'package:soutnaqi/features/settings/data/settings_repository.dart';
import 'package:soutnaqi/features/workspace/cubit/workspace_state.dart';
import 'package:soutnaqi/features/workspace/ui/widgets/workspace_processing_tools.dart';
import 'package:soutnaqi/features/workspace/ui/widgets/workspace_video_tools.dart';
import 'package:soutnaqi/l10n/app_localizations.dart';

void main() {
  for (final locale in [const Locale('ar'), const Locale('en')]) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'separation actions work in ${locale.languageCode} ${brightness.name}',
        (tester) async {
          final cubit = SettingsCubit(repository: SettingsRepository());
          addTearDown(cubit.close);
          var audioMusic = 0;
          var videoMusic = 0;
          var selection = 0;
          const state = WorkspaceState();
          await tester.pumpWidget(
            MaterialApp(
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: ThemeData(brightness: brightness),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      WorkspaceProcessingTools(
                        settingsCubit: cubit,
                        state: state,
                        onNormalize: () {},
                        onNoiseReduction: () {},
                        onChangeSpeed: () {},
                        onIsolateVocals: () {},
                        onIsolateMusic: () => audioMusic++,
                        onIsolateSelection: () => selection++,
                      ),
                      WorkspaceVideoTools(
                        settingsCubit: cubit,
                        state: state,
                        onExtractAudio: () {},
                        onCompress: () {},
                        onIsolateVocals: () {},
                        onIsolateMusic: () => videoMusic++,
                        onChangeSpeed: () {},
                        onMuteVideo: () {},
                        onReplaceAudio: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          final l10n = AppLocalizations.of(
            tester.element(find.byType(Scaffold)),
          );
          final music = find.text(l10n.processIsolateMusic);
          expect(music, findsNWidgets(2));
          await tester.ensureVisible(music.first);
          await tester.tap(music.first);
          final selected = find.text(l10n.processIsolateSelection);
          await tester.ensureVisible(selected);
          await tester.tap(selected);
          await tester.ensureVisible(music.last);
          await tester.tap(music.last);
          expect((audioMusic, videoMusic, selection), (1, 1, 1));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
