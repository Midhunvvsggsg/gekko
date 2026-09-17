import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gekko/providers/theme_provider.dart';
import 'package:gekko/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeMode & SunMoonToggle Tests', () {
    test('ThemeNotifier toggles between light and dark mode and persists preference', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService(prefs);
      final notifier = ThemeNotifier(storage);

      expect(notifier.state, equals(ThemeMode.light));

      await notifier.toggleTheme();
      expect(notifier.state, equals(ThemeMode.dark));
      expect(storage.prefs.getString('gekko_theme_mode'), equals('dark'));

      await notifier.toggleTheme();
      expect(notifier.state, equals(ThemeMode.light));
      expect(storage.prefs.getString('gekko_theme_mode'), equals('light'));
    });
  });
}
