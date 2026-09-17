import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import 'settings_provider.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final StorageService _storage;

  ThemeNotifier(this._storage)
      : super(_loadInitialTheme(_storage));

  static ThemeMode _loadInitialTheme(StorageService storage) {
    final modeStr = storage.prefs.getString('gekko_theme_mode');
    if (modeStr == 'dark') return ThemeMode.dark;
    if (modeStr == 'light') return ThemeMode.light;
    return ThemeMode.light; // Default to Dispatch Console light mode
  }

  Future<void> toggleTheme() async {
    final nextMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    state = nextMode;
    await _storage.prefs.setString('gekko_theme_mode', nextMode == ThemeMode.dark ? 'dark' : 'light');
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _storage.prefs.setString('gekko_theme_mode', mode == ThemeMode.dark ? 'dark' : 'light');
  }
}

final themeModeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ThemeNotifier(storage);
});
