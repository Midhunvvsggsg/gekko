import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import 'settings_provider.dart';

/// Secret Codes for Stealth Mode Disguise:
/// - unlockCode: '1957=' Exits Calculator disguise & returns to Gekko Console
/// - panicCode:  '911='  Triggers Silent SOS Emergency Escalation in background
class StealthCodes {
  static const String defaultUnlockCode = '1957';
  static const String defaultPanicCode = '911';
}

class StealthState {
  final bool isStealthFeatureEnabled;
  final bool isStealthModeActive;
  final String unlockCode;
  final String panicCode;

  const StealthState({
    required this.isStealthFeatureEnabled,
    required this.isStealthModeActive,
    required this.unlockCode,
    required this.panicCode,
  });

  StealthState copyWith({
    bool? isStealthFeatureEnabled,
    bool? isStealthModeActive,
    String? unlockCode,
    String? panicCode,
  }) {
    return StealthState(
      isStealthFeatureEnabled: isStealthFeatureEnabled ?? this.isStealthFeatureEnabled,
      isStealthModeActive: isStealthModeActive ?? this.isStealthModeActive,
      unlockCode: unlockCode ?? this.unlockCode,
      panicCode: panicCode ?? this.panicCode,
    );
  }
}

class StealthNotifier extends StateNotifier<StealthState> {
  final StorageService _storage;

  StealthNotifier(this._storage)
      : super(StealthState(
          isStealthFeatureEnabled: _storage.getStealthFeatureEnabled(),
          isStealthModeActive: _storage.getStealthMode(),
          unlockCode: _storage.getStealthUnlockCode(),
          panicCode: _storage.getStealthPanicCode(),
        ));

  Future<void> setFeatureEnabled(bool enabled) async {
    await _storage.saveStealthFeatureEnabled(enabled);
    if (!enabled && state.isStealthModeActive) {
      await _storage.saveStealthMode(false);
      state = state.copyWith(isStealthFeatureEnabled: false, isStealthModeActive: false);
    } else {
      state = state.copyWith(isStealthFeatureEnabled: enabled);
    }
  }

  Future<void> setStealthMode(bool active) async {
    if (active && !state.isStealthFeatureEnabled) return;
    await _storage.saveStealthMode(active);
    state = state.copyWith(isStealthModeActive: active);
  }

  Future<void> updateUnlockCode(String code) async {
    final clean = code.trim().isEmpty ? StealthCodes.defaultUnlockCode : code.trim();
    await _storage.saveStealthUnlockCode(clean);
    state = state.copyWith(unlockCode: clean);
  }

  Future<void> updatePanicCode(String code) async {
    final clean = code.trim().isEmpty ? StealthCodes.defaultPanicCode : code.trim();
    await _storage.saveStealthPanicCode(clean);
    state = state.copyWith(panicCode: clean);
  }

  Future<void> enableStealth() => setStealthMode(true);
  Future<void> disableStealth() => setStealthMode(false);
}

final stealthProvider = StateNotifierProvider<StealthNotifier, StealthState>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return StealthNotifier(storage);
});
