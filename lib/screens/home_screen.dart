import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/journey.dart';
import '../models/journey_mode_config.dart';
import '../providers/journey_provider.dart';
import '../providers/contacts_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/stealth_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _revealDuress = false;

  @override
  Widget build(BuildContext context) {
    final activeJourney = ref.watch(journeyProvider);
    final contacts = ref.watch(contactsProvider);
    final duressPhrase = ref.watch(settingsProvider.select((s) => s.duressPhrase));
    final isDemoMode = ref.watch(settingsProvider.select((s) => s.isDemoMode));
    final isStealthFeatureEnabled = ref.watch(stealthProvider.select((s) => s.isStealthFeatureEnabled));

    final isDuressVisible = isDemoMode || _revealDuress;
    final displayDuressText = duressPhrase.isEmpty
        ? 'Not set'
        : (isDuressVisible ? duressPhrase : '••••••••');

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.border, width: 1.0),
              ),
              child: const Icon(Icons.shield_outlined, color: AppColors.textPrimary, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GEKKO',
                  style: GoogleFonts.spaceGrotesk(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'SAFETY DISPATCH CONSOLE',
                  style: GoogleFonts.ibmPlexMono(
                    letterSpacing: 0.8,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary, size: 20),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Active Journey Alert Banner (if journey in progress)
                if (activeJourney != null && activeJourney.status != JourneyStatus.completed) ...[
                  _buildActiveJourneyCard(context, activeJourney),
                  const SizedBox(height: 16),
                ],

                // Main Dispatch Hero Section
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.border, width: 1.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Console Status Tag: Left green border, white bg, dark text
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: const BoxDecoration(
                              color: AppColors.surface,
                              border: Border(
                                left: BorderSide(color: AppColors.safeGreen, width: 4.0),
                                top: BorderSide(color: AppColors.border, width: 1.0),
                                right: BorderSide(color: AppColors.border, width: 1.0),
                                bottom: BorderSide(color: AppColors.border, width: 1.0),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.circle, size: 6, color: AppColors.safeGreen),
                                const SizedBox(width: 6),
                                Text(
                                  'DISPATCH ENGINE ACTIVE',
                                  style: GoogleFonts.ibmPlexMono(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            contacts.isEmpty ? 'NO CONTACTS' : '${contacts.length} CONTACTS CONFIGURED',
                            style: GoogleFonts.ibmPlexMono(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Initialize Safety Journey Monitoring',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Select transport profile to activate real-time GPS instrumentation and conversational AI check-in scheduler.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/setup'),
                          icon: const Icon(Icons.navigation_outlined, size: 18),
                          label: const Text('Start Monitored Journey'),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Quick Action Shortcuts Grid
                Text(
                  'DISPATCH CONTROLS',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 550;
                    return GridView.count(
                      crossAxisCount: isWide ? 4 : 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: isWide ? 1.5 : 2.5,
                      children: [
                        _buildQuickActionTile(
                          context,
                          icon: Icons.phone_callback_outlined,
                          title: 'Fake Call Exit',
                          subtitle: 'Simulate emergency call playback',
                          onTap: () => context.push('/fake-call'),
                        ),
                        _buildQuickActionTile(
                          context,
                          icon: Icons.contacts_outlined,
                          title: 'Emergency Contacts',
                          subtitle: '${contacts.length} network recipients',
                          onTap: () => context.push('/contacts'),
                        ),
                        _buildQuickActionTile(
                          context,
                          icon: Icons.shield_outlined,
                          title: 'Duress Safety',
                          subtitle: 'Phrase: "$displayDuressText"',
                          trailing: isDemoMode
                              ? null
                              : GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _revealDuress = !_revealDuress;
                                    });
                                  },
                                  child: Icon(
                                    isDuressVisible ? Icons.visibility_off : Icons.visibility,
                                    size: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                          onTap: () => context.push('/settings'),
                        ),
                        _buildQuickActionTile(
                          context,
                          icon: isStealthFeatureEnabled ? Icons.calculate_outlined : Icons.lock_outlined,
                          title: 'Stealth Disguise',
                          subtitle: isStealthFeatureEnabled ? 'Stock calculator shell' : 'Disabled in Settings',
                          trailing: isStealthFeatureEnabled
                              ? null
                              : const Icon(Icons.lock, size: 14, color: AppColors.textSecondary),
                          onTap: () {
                            if (isStealthFeatureEnabled) {
                              ref.read(stealthProvider.notifier).enableStealth();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Stealth Mode feature is disabled in Settings. Enable it in Settings to use.'),
                                ),
                              );
                            }
                          },
                        ),
                        _buildQuickActionTile(
                          context,
                          icon: Icons.chat_bubble_outline,
                          title: 'AI Chat Companion',
                          subtitle: 'Proactive trip safety chat',
                          onTap: () => context.push('/chat-companion'),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Monitoring Modes Structured Table Block
                Text(
                  'SUPPORTED MONITORING PROFILES',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),

                // Single Structured Table Block with Hairline Dividers
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.border, width: 1.0),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: JourneyModeConfig.defaultModes.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (context, index) {
                      final mode = JourneyModeConfig.defaultModes[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.border, width: 1.0),
                              ),
                              child: Icon(mode.icon, color: AppColors.textPrimary, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        mode.label,
                                        style: GoogleFonts.spaceGrotesk(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Monospace Rectangular Tag (4px max)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceVariant,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: AppColors.border, width: 1.0),
                                        ),
                                        child: Text(
                                          'INTERVAL: ${mode.checkInInterval.inMinutes}M',
                                          style: GoogleFonts.ibmPlexMono(
                                            fontSize: 10,
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    mode.modeDescription,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveJourneyCard(BuildContext context, Journey journey) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: const Border(
          left: BorderSide(color: AppColors.primary, width: 4.0),
          top: BorderSide(color: AppColors.border, width: 1.0),
          right: BorderSide(color: AppColors.border, width: 1.0),
          bottom: BorderSide(color: AppColors.border, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.navigation_outlined, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ACTIVE JOURNEY • ${journey.mode.label.toUpperCase()}',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'En route to ${journey.destinationName}',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => context.push('/active'),
            child: const Text('View Console'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.border, width: 1.0),
        ),
        child: Row(
          children: [
            // Plain line icon in square container with 1px border (NO pastel background block)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.border, width: 1.0),
              ),
              child: Icon(icon, color: AppColors.textPrimary, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 4),
              trailing,
            ],
          ],
        ),
      ),
    );
  }
}
