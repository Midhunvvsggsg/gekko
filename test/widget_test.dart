import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gekko/main.dart';
import 'package:gekko/services/storage_service.dart';
import 'package:gekko/providers/settings_provider.dart';

void main() {
  testWidgets('Gekko App loads home title test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storageService = await StorageService.init();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storageService),
        ],
        child: const GekkoApp(),
      ),
    );

    expect(find.text('GEKKO'), findsOneWidget);
  });
}
