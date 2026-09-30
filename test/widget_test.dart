import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soutnaqi/app.dart';

import 'package:soutnaqi/core/constants/layout_constants.dart';
import 'package:soutnaqi/core/storage/preferences_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PreferencesStore.instance.resetForTesting();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('SoutNaqi opens on onboarding for new users',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const SoutNaqiApp());
    await tester.pump();
    await tester.pump(kSplashMinDuration + const Duration(milliseconds: 200));
    await tester.pump();
    expect(find.text('Welcome to Sout Naqi'), findsOneWidget);
  });

  testWidgets('SoutNaqi opens on the workspace when onboarding is completed',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'settings_onboarding_completed': true,
      'settings_model_guide_completed': true,
    });
    await tester.pumpWidget(const SoutNaqiApp());
    await tester.pump();
    await tester.pump(kSplashMinDuration + const Duration(milliseconds: 200));
    await tester.pump();
    expect(find.text('Import your media'), findsOneWidget);
  });
}
