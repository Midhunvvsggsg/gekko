import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_service.dart';
import 'settings_provider.dart';

final aiServiceProvider = Provider<AIService>((ref) {
  final apiKey = ref.watch(settingsProvider.select((s) => s.apiKey));
  return AIService(apiKey: apiKey);
});
