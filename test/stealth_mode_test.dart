import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gekko/services/storage_service.dart';
import 'package:gekko/providers/settings_provider.dart';
import 'package:gekko/providers/stealth_provider.dart';
import 'package:gekko/screens/calculator_screen.dart';

void main() {
  testWidgets('CalculatorScreen performs arithmetic correctly', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storageService = StorageService(prefs);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storageService),
        ],
        child: const MaterialApp(
          home: CalculatorScreen(),
        ),
      ),
    );

    // Verify initial display is '0'
    expect(find.text('0'), findsWidgets);

    // Tap 5 + 3 =
    await tester.tap(find.text('5'));
    await tester.pump();
    await tester.tap(find.text('+'));
    await tester.pump();
    await tester.tap(find.text('3'));
    await tester.pump();
    await tester.tap(find.text('='));
    await tester.pump();

    // Expect result '8' in display area (fontSize 72)
    expect(
      find.byWidgetPredicate((w) => w is Text && w.data == '8' && w.style?.fontSize == 72),
      findsOneWidget,
    );
  });

  testWidgets('CalculatorScreen 1957= triggers stealth disable', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'gekko_stealth_mode': true});
    final prefs = await SharedPreferences.getInstance();
    final storageService = StorageService(prefs);

    late ProviderContainer providerContainer;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: providerContainer = ProviderContainer(
          overrides: [
            storageServiceProvider.overrideWithValue(storageService),
          ],
        ),
        child: const MaterialApp(
          home: CalculatorScreen(),
        ),
      ),
    );

    expect(providerContainer.read(stealthProvider).isStealthModeActive, isTrue);

    // Tap 1 9 5 7 =
    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.tap(find.text('9'));
    await tester.pump();
    await tester.tap(find.text('5'));
    await tester.pump();
    await tester.tap(find.text('7'));
    await tester.pump();
    await tester.tap(find.text('='));
    await tester.pump();

    // Verify stealth mode disabled
    expect(providerContainer.read(stealthProvider).isStealthModeActive, isFalse);
  });
}
