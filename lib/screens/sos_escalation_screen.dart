import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../providers/journey_provider.dart';
import '../providers/contacts_provider.dart';

class SosEscalationScreen extends ConsumerStatefulWidget {
  const SosEscalationScreen({super.key});

  @override
  ConsumerState<SosEscalationScreen> createState() => _SosEscalationScreenState();
}

class _SosEscalationScreenState extends ConsumerState<SosEscalationScreen> {
  int _dispatchCountdown = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_dispatchCountdown > 0) {
        setState(() {
          _dispatchCountdown--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _cancelEscalation() {
    ref.read(journeyProvider.notifier).cancelJourney();
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final journey = ref.watch(journeyProvider);
    final contacts = ref.watch(contactsProvider);

    final summaryText = journey?.incidentSummary ?? "🚨 EMERGENCY INCIDENT REPORT\n\n• Trigger: SOS Alarm\n• Status: Contact Notification Dispatched";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.sosRed, // #B3261E Deep Red
        foregroundColor: Colors.white,
        title: Text(
          'EMERGENCY DISPATCH ESCALATION',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, letterSpacing: 0.8, fontSize: 15),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. High-Alert Dispatch Card (Deep Red #B3261E, 4px max radius)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.sosRed,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 36, color: Colors.white),
                      const SizedBox(height: 8),
                      Text(
                        'EMERGENCY SOS ACTIVE',
                        style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1.0),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _dispatchCountdown > 0
                            ? 'Simulating automated emergency call dispatch in $_dispatchCountdown seconds...'
                            : 'Automated 911 / Emergency dispatch protocol triggered.',
                        style: GoogleFonts.ibmPlexMono(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 2. AI Incident Summary Card (Monospace instrumentation readout)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(4),
                    border: const Border(
                      left: BorderSide(color: AppColors.sosRed, width: 4.0),
                      top: BorderSide(color: AppColors.border, width: 1.0),
                      right: BorderSide(color: AppColors.border, width: 1.0),
                      bottom: BorderSide(color: AppColors.border, width: 1.0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.description_outlined, color: AppColors.sosRed, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'AI INCIDENT DISPATCH REPORT',
                            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const Divider(height: 20, color: AppColors.border),
                      SelectableText(
                        summaryText,
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 12,
                          height: 1.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 3. Contact Notification Table View
                Text(
                  'EMERGENCY NETWORK NOTIFICATIONS (SIMULATED)',
                  style: GoogleFonts.ibmPlexMono(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: 0.8),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Automated SMS payloads dispatched to registered contacts:',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),

                if (contacts.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.border, width: 1.0),
                    ),
                    child: const Text('No contacts configured.'),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.border, width: 1.0),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: contacts.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (context, index) {
                        final c = contacts[index];
                        return Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.sms_outlined, color: AppColors.primary, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${c.name} (${c.phone})',
                                    style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 13),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.safeGreenBg,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: AppColors.safeGreenBorder, width: 1.0),
                                    ),
                                    child: Text(
                                      'DISPATCHED',
                                      style: GoogleFonts.ibmPlexMono(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.safeGreen),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '🚨 GEKKO ALERT: ${c.name}, emergency SOS triggered for your contact during a ${journey?.mode.label ?? 'Walking'} journey to ${journey?.destinationName ?? 'destination'}. Live map: https://gekko.app/track/${journey?.id ?? '12345'}',
                                  style: GoogleFonts.ibmPlexMono(fontSize: 11, color: AppColors.textPrimary, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 24),

                // 4. Cancel / Safe Button
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _cancelEscalation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(
                      'I AM SAFE — DEESCALATE EMERGENCY',
                      style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w700),
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
