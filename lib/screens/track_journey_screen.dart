import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import '../services/journey_sync_service.dart';
import '../utils/time_utils.dart';

class TrackJourneyScreen extends ConsumerStatefulWidget {
  final String journeyId;

  const TrackJourneyScreen({super.key, required this.journeyId});

  @override
  ConsumerState<TrackJourneyScreen> createState() => _TrackJourneyScreenState();
}

class _TrackJourneyScreenState extends ConsumerState<TrackJourneyScreen> {
  final MapController _mapController = MapController();
  Timer? _tickerTimer;
  int _secondsSinceUpdate = 0;

  @override
  void initState() {
    super.initState();
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() {
          _secondsSinceUpdate++;
        });
      }
    });
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final syncService = ref.watch(journeySyncServiceProvider);

    return StreamBuilder<PublicJourneySnapshot?>(
      stream: syncService.streamSnapshot(widget.journeyId),
      builder: (context, snapshot) {
        final data = snapshot.data;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC), // Slate-50 calm background
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Row(
              children: [
                const Icon(Icons.share_location_outlined, color: Color(0xFF1E293B), size: 20),
                const SizedBox(width: 8),
                Text(
                  'GEKKO LIVE JOURNEY TRACKER',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          body: data == null
              ? _buildNotFoundView()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Status Alert Banner
                          _buildStatusBanner(data),

                          const SizedBox(height: 16),

                          // 2. Journey Overview Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'PROFILE: ${data.modeLabel.toUpperCase()}',
                                        style: GoogleFonts.ibmPlexMono(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF2563EB),
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Row(
                                      children: [
                                        const Icon(Icons.sync, size: 14, color: Color(0xFF64748B)),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Updated $_secondsSinceUpdate s ago',
                                          style: GoogleFonts.ibmPlexMono(
                                            fontSize: 11,
                                            color: const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'En route to ${data.destinationName}',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.schedule_outlined, size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'Started at ${TimeUtils.formatKolkataTime(data.startTime)} • Expected Arrival: ${TimeUtils.formatKolkataTime(data.startTime.add(Duration(minutes: data.expectedDurationMinutes)))}',
                                        style: TextStyle(fontSize: 12, color: Colors.grey[800], fontWeight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // 3. Map Card
                          Container(
                            height: 320,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: data.lastKnownLocation,
                                initialZoom: 15.0,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.gekko.safety.app',
                                ),
                                if (data.routePoints.length > 1)
                                  PolylineLayer(
                                    polylines: [
                                      Polyline(
                                        points: data.routePoints,
                                        strokeWidth: 4.0,
                                        color: const Color(0xFF2563EB),
                                      ),
                                    ],
                                  ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: data.lastKnownLocation,
                                      width: 40,
                                      height: 40,
                                      child: const Icon(
                                        Icons.location_on,
                                        color: Color(0xFFDC2626),
                                        size: 38,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // 4. Last Check-In Status Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: data.lastCheckInStatus == 'safe'
                                        ? const Color(0xFFDCFCE7)
                                        : const Color(0xFFFEF3C7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    data.lastCheckInStatus == 'safe'
                                        ? Icons.check_circle_outline
                                        : Icons.warning_amber_outlined,
                                    color: data.lastCheckInStatus == 'safe'
                                        ? const Color(0xFF166534)
                                        : const Color(0xFF92400E),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'LAST AI CHECK-IN STATUS',
                                        style: GoogleFonts.ibmPlexMono(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        data.lastCheckInStatus == 'safe'
                                            ? 'Verified Safe (Normal Pace & Route)'
                                            : 'Attention Required (Uncertain / Pending)',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
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
        );
      },
    );
  }

  Widget _buildStatusBanner(PublicJourneySnapshot data) {
    if (data.status == 'escalated') {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EMERGENCY ALERT ACTIVE',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF991B1B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'The traveler did not respond to check-in or initiated silent SOS.',
                    style: TextStyle(fontSize: 12, color: Colors.red[800]),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (data.status == 'completed') {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Color(0xFF16A34A), size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'ARRIVED SAFELY • Journey Completed',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF15803D),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF93C5FD), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.navigation_outlined, color: Color(0xFF2563EB), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'ACTIVE MONITORING • Journey In Progress',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1D4ED8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            'Journey Tracking Link Not Found',
            style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'This journey link may be invalid or completed.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
