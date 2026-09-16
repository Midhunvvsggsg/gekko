import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _duressController;
  late TextEditingController _apiKeyController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _duressController = TextEditingController(text: settings.duressPhrase);
    _apiKeyController = TextEditingController(text: settings.apiKey);
  }

  @override
  void dispose() {
    _duressController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final notifier = ref.read(settingsProvider.notifier);
    notifier.updateDuressPhrase(_duressController.text.trim());
    notifier.updateApiKey(_apiKeyController.text.trim());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final hasApiKey = settings.apiKey.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety & App Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Silent Duress Phrase Section
                const Text(
                  '1. Silent Duress Phrase',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                const Text(
                  'If forced to respond to a check-in under threat, inclusion of this secret phrase will silently trigger emergency escalation without revealing danger on-screen.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _duressController,
                  decoration: const InputDecoration(
                    labelText: 'Secret Duress Phrase / Keyword',
                    hintText: 'e.g. pineapple, everything is fine',
                    prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary),
                  ),
                ),

                const SizedBox(height: 24),

                // 2. Gemini AI Integration Settings
                const Text(
                  '2. Gemini AI Integration',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Enter a Gemini API Key to use live Gemini 2.0 Flash models for check-in classification and incident summaries.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: hasApiKey ? AppColors.safeGreenBg : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: hasApiKey ? AppColors.safeGreenBorder : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        hasApiKey ? Icons.check_circle : Icons.info_outline,
                        color: hasApiKey ? AppColors.safeGreen : AppColors.textMuted,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          hasApiKey
                              ? 'Gemini API Key configured and active.'
                              : 'No API Key entered. Offline mode-aware AI fallback active.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: hasApiKey ? AppColors.safeGreen : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: _apiKeyController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Gemini API Key',
                    hintText: 'AIzaSy...',
                    prefixIcon: Icon(Icons.vpn_key_outlined, color: AppColors.primary),
                  ),
                ),

                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _saveSettings,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
