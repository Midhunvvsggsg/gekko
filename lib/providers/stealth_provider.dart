import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import 'settings_provider.dart';

/// Secret Codes for Stealth Mode Disguise:
/// - unlockCode: '1957=' Exits Calculator disguise & returns to Gekko Console
/// - panicCode:  '911='  Triggers Silent SOS Emergency Escalation in background
class StealthCodes {
  static const String unlockCode = '1957';
  static const String panicCode = '911';
}

class StealthState {
  final bool isStealthModeActive;

  const StealthState({
    required this.isStealthModeActive,
  });

  StealthState copyWith({
    bool? isStealthModeActive,
  }) {
    return StealthState(
      isStealthModeActive: isStealthModeActive ?? this.isStealthModeActive,
    );
  }
}

class StealthNotifier extends StateNotifier<StealthState> {
  final StorageService _storage;

  StealthNotifier(this._storage)
      : super(StealthState(
          isStealthModeActive: _storage.getStealthMode(),
        ));

  Future<void> setStealthMode(bool active) async {
    await _storage.saveStealthMode(active);
    state = state.copyWith(isStealthModeActive: active);
  }

  Future<void> enableStealth() => setStealthMode(true);
  Future<void> disableStealth() => setStealthMode(false);
}

final stealthProvider = StateNotifierProvider<StealthNotifier, StealthState>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return StealthNotifier(storage);
});
