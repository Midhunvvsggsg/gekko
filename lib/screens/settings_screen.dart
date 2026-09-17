import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../providers/settings_provider.dart';
import '../providers/stealth_provider.dart';

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
      const SnackBar(content: Text('Console settings saved.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isStealth = ref.watch(stealthProvider.select((s) => s.isStealthModeActive));
    final hasApiKey = settings.apiKey.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'DISPATCH CONSOLE CONFIGURATION',
          style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Silent Duress Phrase Section
                Text(
                  '1. SILENT DURESS PHRASE',
                  style: GoogleFonts.ibmPlexMono(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: 0.8),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Inclusion of this keyword in any check-in response silently dispatches emergency escalation without visual alert changes.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: _duressController,
                  style: GoogleFonts.ibmPlexSans(fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Secret Duress Keyword',
                    hintText: 'e.g. pineapple, everything is fine',
                    prefixIcon: Icon(Icons.lock_outlined, color: AppColors.textPrimary, size: 18),
                  ),
                ),

                const SizedBox(height: 20),

                // 2. Gemini AI Integration Settings
                Text(
                  '2. GEMINI AI TELEMETRY ENGINE',
                  style: GoogleFonts.ibmPlexMono(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: 0.8),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Configure Gemini 2.0 Flash REST endpoint key for real-time natural language check-in classification and incident summary dispatches.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),

                // Rectangular Status Tag with Left Border Accent
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: hasApiKey ? AppColors.safeGreenBg : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                    border: Border(
                      left: BorderSide(
                        color: hasApiKey ? AppColors.safeGreen : AppColors.textSecondary,
                        width: 4.0,
                      ),
                      top: const BorderSide(color: AppColors.border, width: 1.0),
                      right: const BorderSide(color: AppColors.border, width: 1.0),
                      bottom: const BorderSide(color: AppColors.border, width: 1.0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        hasApiKey ? Icons.check_circle_outlined : Icons.info_outlined,
                        color: hasApiKey ? AppColors.safeGreen : AppColors.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          hasApiKey
                              ? 'GEMINI REST TELEMETRY: KEY ACTIVE'
                              : 'GEMINI REST TELEMETRY: DUAL-LAYER FALLBACK ENGINE ACTIVE',
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: hasApiKey ? AppColors.safeGreen : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                TextField(
                  controller: _apiKeyController,
                  obscureText: true,
                  style: GoogleFonts.ibmPlexMono(fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Gemini API Key',
                    hintText: 'AIzaSy...',
                    prefixIcon: Icon(Icons.vpn_key_outlined, color: AppColors.textPrimary, size: 18),
                  ),
                ),

                const SizedBox(height: 20),

                // 3. Judge / Demo Mode Toggle Section
                Text(
                  '3. JUDGE / DEMO EVALUATION MODE',
                  style: GoogleFonts.ibmPlexMono(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: 0.8),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Enable compressed 15s check-in countdown timers, reveal duress phrases on Home, and display raw Gemini AI classification JSON payloads.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),

                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: settings.isDemoMode ? AppColors.warningAmber : AppColors.border,
                      width: settings.isDemoMode ? 1.5 : 1.0,
                    ),
                  ),
                  child: SwitchListTile(
                    value: settings.isDemoMode,
                    activeThumbColor: AppColors.primary,
                    activeTrackColor: AppColors.surfaceVariant,
                    onChanged: (val) {
                      ref.read(settingsProvider.notifier).toggleDemoMode(val);
                    },
                    title: Text(
                      'DEMO MODE (HACKATHON EVALUATION)',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: settings.isDemoMode ? AppColors.warningAmber : AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      settings.isDemoMode
                          ? 'ACTIVE: Timers compressed to 15s • Duress phrase visible • AI JSON internals panel enabled.'
                          : 'INACTIVE: Normal real-world interval timing and standard production layout.',
                      style: GoogleFonts.ibmPlexMono(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 4. Stealth Disguise Mode Section
                Text(
                  '4. STEALTH DISGUISE MODE (CALCULATOR SHELL)',
                  style: GoogleFonts.ibmPlexMono(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: 0.8),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Disguises Gekko as a functioning stock Calculator app while GPS monitoring, silent panic, and passive AI check-ins continue running invisibly.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),

                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isStealth ? AppColors.primary : AppColors.border,
                      width: isStealth ? 1.5 : 1.0,
                    ),
                  ),
                  child: SwitchListTile(
                    value: isStealth,
                    activeThumbColor: AppColors.primary,
                    activeTrackColor: AppColors.surfaceVariant,
                    onChanged: (val) {
                      ref.read(stealthProvider.notifier).setStealthMode(val);
                    },
                    title: Text(
                      'ENABLE STEALTH MODE (CALCULATOR DISGUISE)',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isStealth ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      isStealth
                          ? 'DISGUISED: App shell swapped to stock Calculator app.'
                          : 'INACTIVE: Standard Gekko Dispatch Console UI.',
                      style: GoogleFonts.ibmPlexMono(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Secret Code Guide Reference Card (no borderRadius with left border accent)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceVariant,
                    border: Border(
                      left: BorderSide(color: AppColors.primary, width: 4.0),
                      top: BorderSide(color: AppColors.border, width: 1.0),
                      right: BorderSide(color: AppColors.border, width: 1.0),
                      bottom: BorderSide(color: AppColors.border, width: 1.0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SECRET DISGUISE CODES (CALCULATOR KEYPAD)',
                        style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            color: AppColors.primary,
                            child: Text(
                              '${StealthCodes.unlockCode}=',
                              style: GoogleFonts.ibmPlexMono(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Return to real Gekko Console UI',
                              style: GoogleFonts.ibmPlexSans(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            color: AppColors.sosRed,
                            child: Text(
                              '${StealthCodes.panicCode}=',
                              style: GoogleFonts.ibmPlexMono(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Trigger Silent Emergency Panic SOS (Zero visual feedback change)',
                              style: GoogleFonts.ibmPlexSans(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Save Button (4px max rectangular navy button)
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _saveSettings,
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: Text(
                      'SAVE CONFIGURATION',
                      style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                    ),
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

