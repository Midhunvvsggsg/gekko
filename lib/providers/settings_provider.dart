import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('Initialize storageServiceProvider in ProviderScope override');
});

class SettingsState {
  final String duressPhrase;
  final int checkInFreqOffsetMins;
  final String apiKey;

  SettingsState({
    required this.duressPhrase,
    required this.checkInFreqOffsetMins,
    required this.apiKey,
  });

  SettingsState copyWith({
    String? duressPhrase,
    int? checkInFreqOffsetMins,
    String? apiKey,
  }) {
    return SettingsState(
      duressPhrase: duressPhrase ?? this.duressPhrase,
      checkInFreqOffsetMins: checkInFreqOffsetMins ?? this.checkInFreqOffsetMins,
      apiKey: apiKey ?? this.apiKey,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final StorageService _storage;

  SettingsNotifier(this._storage)
      : super(SettingsState(
          duressPhrase: _storage.getDuressPhrase(),
          checkInFreqOffsetMins: _storage.getCheckInFreqMinutes(),
          apiKey: _storage.getApiKey() ?? const String.fromEnvironment('GEMINI_API_KEY', defaultValue: ''),
        ));

  Future<void> updateDuressPhrase(String phrase) async {
    await _storage.saveDuressPhrase(phrase);
    state = state.copyWith(duressPhrase: phrase);
  }

  Future<void> updateCheckInFreq(int mins) async {
    await _storage.saveCheckInFreqMinutes(mins);
    state = state.copyWith(checkInFreqOffsetMins: mins);
  }

  Future<void> updateApiKey(String key) async {
    await _storage.saveApiKey(key);
    state = state.copyWith(apiKey: key);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return SettingsNotifier(storage);
});
