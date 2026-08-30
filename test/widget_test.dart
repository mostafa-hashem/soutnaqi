import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soutnaqi/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('SoutNaqi opens on the workspace', (WidgetTester tester) async {
    await tester.pumpWidget(const SoutNaqiApp());
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Import your media'), findsOneWidget);
  });
}
