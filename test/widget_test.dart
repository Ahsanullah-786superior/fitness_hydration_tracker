import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:fitness_hydration_tracker/main.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('app launches and shows the home title', (tester) async {
    await tester.pumpWidget(const FitnessHydrationApp());
    await tester.pumpAndSettle();

    expect(find.text('Fitness & Hydration Tracker'), findsOneWidget);
  });
}
