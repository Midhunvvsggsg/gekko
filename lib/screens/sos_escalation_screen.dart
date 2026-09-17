import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../providers/journey_provider.dart';
import '../providers/contacts_provider.dart';
import '../providers/settings_provider.dart';
import '../models/sos_hop_packet.dart';
import '../providers/mesh_relay_provider.dart';

class SosEscalationScreen extends ConsumerStatefulWidget {
  const SosEscalationScreen({super.key});

  @override
  ConsumerState<SosEscalationScreen> createState() => _SosEscalationScreenState();
}

class _SosEscalationScreenState extends ConsumerState<SosEscalationScreen> {
  int _cancelWindowSeconds = 15;
  Timer? _countdownTimer;
  bool _isDispatchConfirmed = false;
  bool _showInternals = false;

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_cancelWindowSeconds > 0) {
        setState(() {
          _cancelWindowSeconds--;
        });
      } else {
        _countdownTimer?.cancel();
        if (mounted) {
          setState(() {
            _isDispatchConfirmed = true;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _cancelEscalation() {
    _countdownTimer?.cancel();
    ref.read(journeyProvider.notifier).cancelJourney();
    context.go('/home');
  }

  void _markResolved() {
    _countdownTimer?.cancel();
    ref.read(journeyProvider.notifier).cancelJourney();
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final journey = ref.watch(journeyProvider);
    final contacts = ref.watch(contactsProvider);
    final isDemoMode = ref.watch(settingsProvider.select((s) => s.isDemoMode));

    final summaryText = journey?.incidentSummary ??
        "🚨 EMERGENCY INCIDENT REPORT\n\n• Trigger Reason: Manual Emergency SOS Alarm\n• Last Known Location: 37.7749, -122.4194 (Union Square, SF)\n• Journey Mode: ${journey?.mode.label ?? 'Walking'}\n• Elapsed Time: ${journey != null ? DateTime.now().difference(journey.startTime).inMinutes : 12} mins\n• Status: Automated emergency contact payloads dispatched.";

    final triggerReason = journey?.checkIns.isNotEmpty == true && journey!.checkIns.last.classification != null
        ? journey.checkIns.last.classification!.rationale
        : (journey?.isDeviated == true ? 'Route deviation detected' : 'SOS Emergency Alarm');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.sosRed, // #B3261E Deep Red
        foregroundColor: Colors.white,
        title: Text(
          'HIGH-ALERT EMERGENCY DISPATCH',
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
                // 1. Full-Screen High-Alert Cancel Banner (Shown during 15s grace window)
                if (!_isDispatchConfirmed && _cancelWindowSeconds > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.sosRed, // #B3261E Deep Red
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.white),
                        const SizedBox(height: 10),
                        Text(
                          'EMERGENCY DISPATCH IN ${_cancelWindowSeconds}s',
                          style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1.0),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Automated 911 dispatch & emergency SMS alerts will be sent automatically when countdown expires.',
                          style: GoogleFonts.ibmPlexMono(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _cancelEscalation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.sosRed,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            child: Text(
                              'CANCEL EMERGENCY DISPATCH',
                              style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 2. Status Header Tag (Red left-stripe status tag)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                      left: BorderSide(color: AppColors.sosRed, width: 4.0),
                      top: BorderSide(color: AppColors.border, width: 1.0),
                      right: BorderSide(color: AppColors.border, width: 1.0),
                      bottom: BorderSide(color: AppColors.border, width: 1.0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.sosRedBg,
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(color: AppColors.sosRedBorder, width: 1.0),
                        ),
                        child: Text(
                          'DISPATCH ALERT ACTIVE',
                          style: GoogleFonts.ibmPlexMono(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.sosRed, letterSpacing: 0.8),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'INCIDENT ID: #${journey?.id ?? '99201'}',
                        style: GoogleFonts.ibmPlexMono(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 3. AI Generated Incident Breakdown Card
                Container(
                  padding: const EdgeInsets.all(16),
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
                          const Icon(Icons.description_outlined, color: AppColors.sosRed, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'GEMINI INCIDENT SUMMARY',
                            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const Divider(height: 20, color: AppColors.border),
                      _buildIncidentRow('Trigger Reason', triggerReason),
                      _buildIncidentRow('Last Location', '${journey?.currentPosition.latitude.toStringAsFixed(4) ?? "37.7749"}, ${journey?.currentPosition.longitude.toStringAsFixed(4) ?? "-122.4194"} (${journey?.destinationName ?? "Union Square"})'),
                      _buildIncidentRow('Journey Mode', journey?.mode.label ?? 'Walking'),
                      _buildIncidentRow('Elapsed Time', '${journey != null ? DateTime.now().difference(journey.startTime).inMinutes : 14} minutes'),
                      _buildIncidentRow('Last Check-In', journey?.checkIns.isNotEmpty == true ? (journey!.checkIns.last.classification?.status.name.toUpperCase() ?? 'PENDING') : 'UNRESPONSIVE'),
                      const SizedBox(height: 12),
                      SelectableText(
                        summaryText,
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 11,
                          height: 1.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Demo Mode AI Internals Panel
                if (isDemoMode) ...[
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _showInternals = !_showInternals;
                      });
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.border, width: 1.0),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.code_outlined, size: 14, color: AppColors.sosRed),
                          const SizedBox(width: 6),
                          Text(
                            'AI INTERNALS (RAW INCIDENT PAYLOAD)',
                            style: GoogleFonts.ibmPlexMono(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.sosRed),
                          ),
                          const Spacer(),
                          Icon(_showInternals ? Icons.expand_less : Icons.expand_more, size: 16, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                  if (_showInternals) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary, // #0E1A2B Dark Charcoal
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: SelectableText(
                        '{\n  "incidentId": "${journey?.id ?? '99201'}",\n  "trigger": "$triggerReason",\n  "mode": "${journey?.mode.label ?? 'Walking'}",\n  "dispatchConfirmed": ${_isDispatchConfirmed || _cancelWindowSeconds == 0},\n  "recipientsNotified": ${contacts.length}\n}',
                        style: GoogleFonts.ibmPlexMono(fontSize: 10, color: Colors.greenAccent, height: 1.4),
                      ),
                    ),
                  ],
                ],

                // P2P Mesh Network SOS Hopping Telemetry Card
                _buildP2pMeshTelemetryCard(context, ref),

                const SizedBox(height: 20),

                // 4. Contacts Notified Panel with Simulated SMS Payload Text
                Text(
                  'CONTACTS NOTIFIED (SIMULATED SMS PAYLOADS)',
                  style: GoogleFonts.ibmPlexMono(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: 0.8),
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
                    child: const Text('No emergency contacts configured.'),
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

                // 5. Mark Resolved Button
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _markResolved,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(
                      'MARK RESOLVED & RETURN TO CONSOLE',
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

  Widget _buildIncidentRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.ibmPlexMono(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.ibmPlexSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildP2pMeshTelemetryCard(BuildContext context, WidgetRef ref) {
    final meshState = ref.watch(meshRelayProvider);
    final packet = meshState.activePacket;

    if (packet == null) return const SizedBox.shrink();

    final statusText = packet.status == SosHopStatus.towerDelivered
        ? 'DELIVERED TO CELL TOWER'
        : (packet.status == SosHopStatus.relaying
            ? 'RELAYING THROUGH PEER MESH'
            : 'OFFLINE BROADCASTING');

    final statusColor = packet.status == SosHopStatus.towerDelivered
        ? AppColors.safeGreen
        : (packet.status == SosHopStatus.relaying ? AppColors.primary : AppColors.warningAmber);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          'OFFLINE P2P MESH DISPATCH (DELAY-TOLERANT NETWORK)',
          style: GoogleFonts.ibmPlexMono(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
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
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.hub_outlined, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PACKET ID: ${packet.packetId}',
                          style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'STORE-AND-FORWARD P2P HOPPING ENGINE',
                          style: GoogleFonts.ibmPlexMono(fontSize: 10, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: statusColor, width: 1.0),
                    ),
                    child: Text(
                      statusText,
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20, color: AppColors.border),

              // Hop trajectory list graph
              Text(
                'DEVICE HOP TRAJECTORY (${packet.hopCount} HOPS TAKEN):',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: packet.hopHistory.length,
                separatorBuilder: (_, __) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.south, size: 14, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'P2P BLE / Mesh Packet Transfer',
                        style: GoogleFonts.ibmPlexMono(fontSize: 9, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                itemBuilder: (context, idx) {
                  final node = packet.hopHistory[idx];
                  IconData nodeIcon = Icons.smartphone;
                  if (node.nodeType.contains('Vehicle')) {
                    nodeIcon = Icons.directions_car;
                  } else if (node.nodeType.contains('Transit') || node.nodeType.contains('Repeater')) {
                    nodeIcon = Icons.router;
                  } else if (node.nodeType.contains('Tower') || node.nodeType.contains('Gateway')) {
                    nodeIcon = Icons.cell_tower;
                  }

                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.border, width: 1.0),
                    ),
                    child: Row(
                      children: [
                        Icon(nodeIcon, size: 18, color: AppColors.textPrimary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                node.nodeLabel,
                                style: GoogleFonts.spaceGrotesk(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${node.nodeType} • ${node.nodeId}',
                                style: GoogleFonts.ibmPlexMono(fontSize: 10, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${node.timestamp.minute.toString().padLeft(2, '0')}:${node.timestamp.second.toString().padLeft(2, '0')}',
                          style: GoogleFonts.ibmPlexMono(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),

              // Simulation trigger button
              SizedBox(
                width: double.infinity,
                height: 40,
                child: OutlinedButton.icon(
                  onPressed: packet.status == SosHopStatus.towerDelivered
                      ? null
                      : () {
                          ref.read(meshRelayProvider.notifier).simulateHop();
                        },
                  icon: const Icon(Icons.sensors, size: 16),
                  label: Text(
                    packet.status == SosHopStatus.towerDelivered
                        ? 'CELL TOWER GATEWAY REACHED (DELIVERED)'
                        : 'SIMULATE P2P DEVICE HOP (STORE & FORWARD)',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
