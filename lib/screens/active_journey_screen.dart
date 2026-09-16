import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import '../theme/app_colors.dart';
import '../models/journey.dart';
import '../providers/journey_provider.dart';
import 'check_in_modal.dart';

class ActiveJourneyScreen extends ConsumerStatefulWidget {
  const ActiveJourneyScreen({super.key});

  @override
  ConsumerState<ActiveJourneyScreen> createState() => _ActiveJourneyScreenState();
}

class _ActiveJourneyScreenState extends ConsumerState<ActiveJourneyScreen> {
  final MapController _mapController = MapController();
  bool _modalShown = false;

  @override
  Widget build(BuildContext context) {
    final journey = ref.watch(journeyProvider);
    final journeyNotifier = ref.read(journeyProvider.notifier);

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
            Icon(journey.mode.icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Text(
              '${journey.mode.label} Journey',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
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
                      strokeWidth: 5.0,
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
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: journey.isDeviated ? AppColors.sosRedBg : AppColors.primaryContainer,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: journey.isDeviated ? AppColors.sosRed : AppColors.primary,
                          width: 3,
                        ),
                      ),
                      child: Icon(
                        journey.mode.icon,
                        color: journey.isDeviated ? AppColors.sosRed : AppColors.primary,
                        size: 26,
                      ),
                    ),
                  ),

                  // Destination Marker
                  Marker(
                    point: journey.destinationLatLng,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: AppColors.sosRed,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 2. Top Journey Info Bar Overlay
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'DESTINATION',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                            ),
                            Text(
                              journey.destinationName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Countdown Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: journey.isDeviated ? AppColors.sosRedBg : AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: journey.isDeviated ? AppColors.sosRedBorder : AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'NEXT CHECK-IN',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                            ),
                            Text(
                              '$minsStr:$secsStr',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: journey.isDeviated ? AppColors.sosRed : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Off-route Alert Banner if deviated
          if (journey.isDeviated)
            Positioned(
              top: 80,
              left: 16,
              right: 16,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.sosRed,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'UNEXPECTED ROUTE DEVIATION DETECTED! Gekko safety monitoring active.',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
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
            bottom: 16,
            left: 16,
            right: 16,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Simulation Control Buttons Bar
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.spaceEvenly,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ActionChip(
                            avatar: const Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.primary),
                            label: const Text('Check In Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            onPressed: () => _showCheckInModal(context),
                          ),
                          FilterChip(
                            avatar: Icon(
                              Icons.alt_route,
                              size: 16,
                              color: journey.isDeviated ? AppColors.sosRed : AppColors.textSecondary,
                            ),
                            label: Text(
                              journey.isDeviated ? 'Normal Route' : 'Simulate Off-Route',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: journey.isDeviated ? AppColors.sosRed : AppColors.textPrimary,
                              ),
                            ),
                            selected: journey.isDeviated,
                            onSelected: (_) => journeyNotifier.toggleOffRouteDeviation(),
                            selectedColor: AppColors.sosRedBg,
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.phone_callback_rounded, size: 16, color: Colors.blue),
                            label: const Text('Fake Call', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            onPressed: () => context.push('/fake-call'),
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.check_circle_outline, size: 16, color: AppColors.safeGreen),
                            label: const Text('Arrive Safely', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.safeGreen)),
                            onPressed: () => journeyNotifier.completeJourney(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // PERSISTENT SOS BUTTON (Red alert styling)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () => journeyNotifier.triggerSOS(triggerSource: 'Manual SOS Emergency Button Pressed'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.sosRed,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.emergency_rounded, size: 26),
                        label: const Text(
                          'EMERGENCY SOS',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1.0),
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
        title: const Text('Cancel Safety Journey?'),
        content: const Text('This will stop AI check-in monitoring and location tracking.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Keep Monitoring'),
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
