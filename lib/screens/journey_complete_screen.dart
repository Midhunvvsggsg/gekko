import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../providers/journey_provider.dart';

class JourneyCompleteScreen extends ConsumerWidget {
  const JourneyCompleteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journey = ref.watch(journeyProvider);

    final durationMins = journey != null
        ? DateTime.now().difference(journey.startTime).inMinutes.clamp(1, 999)
        : 18;
    final checkInCount = journey?.checkIns.length ?? 2;
    final dest = journey?.destinationName ?? 'Muvattupuzha KSRTC Stand, Ernakulam';
    final modeName = journey?.mode.label ?? 'Walking';

    final aiSummaryText = journey?.arrivalSummary ??
        "$modeName journey to $dest completed in $durationMins minutes with $checkInCount check-ins, all normal.";

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Green Left-Stripe Status Tag
                Container(
                  padding: const EdgeInsets.all(12),
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.safeGreenBg,
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(color: AppColors.safeGreenBorder, width: 1.0),
                        ),
                        child: Text(
                          'JOURNEY COMPLETE',
                          style: GoogleFonts.ibmPlexMono(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.safeGreen, letterSpacing: 0.8),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'STATUS // SAFE ARRIVAL',
                        style: GoogleFonts.ibmPlexMono(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.safeGreen),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'SAFE ARRIVAL CONFIRMED',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Safety monitoring instrumentation for journey to $dest has concluded.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),

                const SizedBox(height: 20),

                // Instrumentation Summary Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.border, width: 1.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn('DURATION', '${durationMins}m', Icons.timer_outlined),
                      _buildStatColumn('CHECK-INS', '$checkInCount', Icons.fact_check_outlined),
                      _buildStatColumn('MODE', modeName, Icons.directions_walk),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // AI Closing Summary Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.border, width: 1.0),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.bolt, color: AppColors.safeGreen, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          aiSummaryText,
                          style: GoogleFonts.ibmPlexMono(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(journeyProvider.notifier).cancelJourney();
                      context.go('/home');
                    },
                    child: Text(
                      'DONE — RETURN TO CONSOLE',
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

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.ibmPlexMono(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.ibmPlexMono(fontSize: 9, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
