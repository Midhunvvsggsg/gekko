import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/journey.dart';
import '../models/journey_mode_config.dart';
import '../providers/journey_provider.dart';
import '../providers/settings_provider.dart';
import 'check_in_modal.dart';

class ActiveJourneyScreen extends ConsumerStatefulWidget {
  const ActiveJourneyScreen({super.key});

  @override
  ConsumerState<ActiveJourneyScreen> createState() => _ActiveJourneyScreenState();
}

class _ActiveJourneyScreenState extends ConsumerState<ActiveJourneyScreen> {
  final MapController _mapController = MapController();
  bool _modalShown = false;

  void _shareJourneyLink(BuildContext context, Journey journey) {
    final trackUrl = Uri.base.origin.contains('http')
        ? '${Uri.base.origin}/#/track/${journey.id}'
        : 'http://localhost:8080/#/track/${journey.id}';

    Clipboard.setData(ClipboardData(text: trackUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Public Journey Tracking Link copied: $trackUrl'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showModeOverrideDialog(BuildContext context, JourneyStateNotifier notifier) {
    showDialog(
      context: context,
      builder: (dialogCtx) => SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: Text('Select Monitoring Profile Override', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
        children: JourneyModeConfig.defaultModes.map((mode) {
          return SimpleDialogOption(
            onPressed: () {
              Navigator.pop(dialogCtx);
              notifier.overrideMode(mode);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(mode.icon, color: AppColors.textPrimary, size: 20),
                  const SizedBox(width: 10),
                  Text(mode.label, style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600, fontSize: 14)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final journey = ref.watch(journeyProvider);
    final journeyNotifier = ref.read(journeyProvider.notifier);
    final isDemoMode = ref.watch(settingsProvider.select((s) => s.isDemoMode));

    // Redirect or trigger popups based on journey status
    if (journey == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/home');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (journey.status == JourneyStatus.escalated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/sos');
      });
    } else if (journey.status == JourneyStatus.completed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/complete');
      });
    } else if (journey.status == JourneyStatus.checkInPending && !_modalShown) {
      _modalShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCheckInModal(context).then((_) {
          _modalShown = false;
        });
      });
    }

    final secondsRemaining = journeyNotifier.secondsToNextCheckIn;
    final minsStr = (secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final secsStr = (secondsRemaining % 60).toString().padLeft(2, '0');

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(journey.mode.icon, color: AppColors.textPrimary, size: 20),
            const SizedBox(width: 8),
            Text(
              '${journey.mode.label.toUpperCase()} DISPATCH INSTRUMENTATION',
              style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.textPrimary),
            tooltip: 'Share Journey Tracking Link',
            onPressed: () => _shareJourneyLink(context, journey),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textPrimary),
            tooltip: 'Cancel Journey',
            onPressed: () => _confirmCancelJourney(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Live Interactive Map (flutter_map)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: journey.currentPosition,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.gekko.safety',
              ),

              // Polyline route layer
              if (journey.routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: journey.routePoints,
                      strokeWidth: 4.0,
                      color: journey.isDeviated ? AppColors.sosRed : AppColors.primary,
                    ),
                  ],
                ),

              // Markers layer (User location & Destination)
              MarkerLayer(
                markers: [
                  // User Current Position Marker
                  Marker(
                    point: journey.currentPosition,
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: journey.isDeviated ? AppColors.sosRedBg : AppColors.surface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: journey.isDeviated ? AppColors.sosRed : AppColors.primary,
                          width: 2.0,
                        ),
                      ),
                      child: Icon(
                        journey.mode.icon,
                        color: journey.isDeviated ? AppColors.sosRed : AppColors.primary,
                        size: 22,
                      ),
                    ),
                  ),

                  // Destination Marker
                  Marker(
                    point: journey.destinationLatLng,
                    width: 36,
                    height: 36,
                    child: const Icon(
                      Icons.location_on,
                      color: AppColors.sosRed,
                      size: 36,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 2. Top Journey Info Bar Overlay
          Positioned(
            top: 14,
            left: 14,
            right: 14,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.border, width: 1.0),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'TARGET DESTINATION',
                                  style: GoogleFonts.ibmPlexMono(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                                ),
                                Text(
                                  journey.destinationName,
                                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Monospace Countdown Instrument Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: journey.isDeviated ? AppColors.sosRedBg : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: journey.isDeviated ? AppColors.sosRedBorder : AppColors.border,
                                width: 1.0,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'NEXT CHECK-IN',
                                  style: GoogleFonts.ibmPlexMono(fontSize: 8, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                                ),
                                Text(
                                  '$minsStr:$secsStr',
                                  style: GoogleFonts.ibmPlexMono(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: journey.isDeviated ? AppColors.sosRed : AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Non-blocking Auto Mode-Switch Banner
                    if (journey.autoSwitchedNotice != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: AppColors.surface,
                          border: Border(
                            left: BorderSide(color: AppColors.primary, width: 4.0),
                            top: BorderSide(color: AppColors.border, width: 1.0),
                            right: BorderSide(color: AppColors.border, width: 1.0),
                            bottom: BorderSide(color: AppColors.border, width: 1.0),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.directions_bus_outlined, color: AppColors.primary, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                journey.autoSwitchedNotice!,
                                style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                              ),
                            ),
                            TextButton(
                              onPressed: () => _showModeOverrideDialog(context, journeyNotifier),
                              child: Text(
                                'Change',
                                style: GoogleFonts.ibmPlexMono(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accentSecondary),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                              onPressed: () => journeyNotifier.dismissAutoSwitchNotice(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // 3. Off-route Alert Banner if deviated
          if (journey.isDeviated)
            Positioned(
              top: journey.autoSwitchedNotice != null ? 140 : 76,
              left: 14,
              right: 14,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.sosRed,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'UNEXPECTED ROUTE DEVIATION DETECTED! High-alert monitoring active.',
                            style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // 4. Bottom Controls & Persistent SOS Button Bar
          Positioned(
            bottom: 14,
            left: 14,
            right: 14,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Simulation Control Buttons Bar
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.border, width: 1.0),
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.spaceEvenly,
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            ),
                            icon: const Icon(Icons.chat_bubble_outline, size: 14, color: AppColors.primary),
                            label: Text('Check In', style: GoogleFonts.ibmPlexMono(fontSize: 11, fontWeight: FontWeight.w600)),
                            onPressed: () => _showCheckInModal(context),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            ),
                            icon: const Icon(Icons.record_voice_over_outlined, size: 14, color: AppColors.primary),
                            label: Text('Voice Companion', style: GoogleFonts.ibmPlexMono(fontSize: 11, fontWeight: FontWeight.w600)),
                            onPressed: () => context.push('/voice-companion'),
                          ),
                          FilterChip(
                            avatar: Icon(
                              Icons.alt_route_outlined,
                              size: 14,
                              color: journey.isDeviated ? AppColors.sosRed : AppColors.textSecondary,
                            ),
                            label: Text(
                              journey.isDeviated ? 'Normal Route' : 'Test Safety',
                              style: GoogleFonts.ibmPlexMono(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: journey.isDeviated ? AppColors.sosRed : AppColors.textPrimary,
                              ),
                            ),
                            selected: journey.isDeviated,
                            onSelected: (_) => journeyNotifier.toggleOffRouteDeviation(),
                            selectedColor: AppColors.sosRedBg,
                          ),
                          if (isDemoMode)
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                side: const BorderSide(color: AppColors.warningAmber, width: 1.0),
                              ),
                              icon: const Icon(Icons.speed_outlined, size: 14, color: AppColors.warningAmber),
                              label: Text('Simulate Speed', style: GoogleFonts.ibmPlexMono(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.warningAmber)),
                              onPressed: () => journeyNotifier.simulateVehicleSpeed(),
                            ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            ),
                            icon: const Icon(Icons.phone_callback_outlined, size: 14, color: AppColors.accentSecondary),
                            label: Text('Fake Call', style: GoogleFonts.ibmPlexMono(fontSize: 11, fontWeight: FontWeight.w600)),
                            onPressed: () => context.push('/fake-call'),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              side: const BorderSide(color: AppColors.safeGreen, width: 1.0),
                            ),
                            icon: const Icon(Icons.check_circle_outline, size: 14, color: AppColors.safeGreen),
                            label: Text('Arrive Safely', style: GoogleFonts.ibmPlexMono(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.safeGreen)),
                            onPressed: () => journeyNotifier.completeJourney(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // PERSISTENT EMERGENCY SOS BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => journeyNotifier.triggerSOS(triggerSource: 'Manual Emergency SOS Pressed'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.sosRed,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        icon: const Icon(Icons.warning_amber_rounded, size: 22),
                        label: Text(
                          'EMERGENCY SOS DISPATCH',
                          style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCheckInModal(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const CheckInModal(),
    );
  }

  void _confirmCancelJourney(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: Text('Cancel Journey Instrumentation?', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
        content: const Text('This will deactivate AI check-in scheduler and location tracking.'),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Keep Active'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              ref.read(journeyProvider.notifier).cancelJourney();
              context.go('/home');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.sosRed),
            child: const Text('Cancel Journey'),
          ),
        ],
      ),
    );
  }
}
