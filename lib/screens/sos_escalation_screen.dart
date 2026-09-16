import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
      backgroundColor: AppColors.sosRedBg,
      appBar: AppBar(
        backgroundColor: AppColors.sosRed,
        foregroundColor: Colors.white,
        title: const Text('GEKKO EMERGENCY ESCALATION', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.0)),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Loud Alert Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.sosRed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.white),
                      const SizedBox(height: 10),
                      const Text(
                        'EMERGENCY SOS ACTIVE',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1.0),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _dispatchCountdown > 0
                            ? 'Simulating automated emergency call in $_dispatchCountdown seconds...'
                            : 'Automated 911 / Emergency dispatch protocol triggered.',
                        style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 2. AI Incident Summary Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.sosRedBorder, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.sosRedBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.description_outlined, color: AppColors.sosRed, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'AI-Generated Incident Report',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      SelectableText(
                        summaryText,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          fontFamily: 'monospace',
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 3. Simulated Contact Notification View
                const Text(
                  'Emergency Contact Notifications (Simulated)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                const Text(
                  'In production, the following SMS message with live GPS track link would be sent immediately:',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),

                if (contacts.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Text('No contacts configured. Go to Settings to add emergency contacts.'),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: contacts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final c = contacts[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.sms_outlined, color: AppColors.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'SMS to ${c.name} (${c.phone})',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.safeGreenBg,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'SENT (SIMULATED)',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.safeGreen),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '🚨 GEKKO SAFETY ALERT: ${c.name}, emergency SOS triggered for your contact during a ${journey?.mode.label ?? 'Walking'} journey to ${journey?.destinationName ?? 'destination'}. Live map & coordinates: https://gekko.app/track/${journey?.id ?? '12345'}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 32),

                // 4. Cancel / Safe Button
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _cancelEscalation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey.shade800,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('I Am Safe — Deescalate Emergency', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
