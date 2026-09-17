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

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.safeGreenBg,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.safeGreenBorder, width: 1.0),
                    ),
                    child: const Icon(
                      Icons.check_circle_outlined,
                      size: 48,
                      color: AppColors.safeGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'JOURNEY COMPLETED SAFELY',
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
                  'Safety monitoring for journey to ${journey?.destinationName ?? 'destination'} has concluded.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),

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
                      _buildStatColumn('CHECK-INS CLEARED', '${journey?.checkIns.length ?? 1}', Icons.fact_check_outlined),
                      _buildStatColumn('MODE PROFILE', journey?.mode.label ?? 'Walking', Icons.directions_walk),
                      _buildStatColumn('SAFETY STATUS', 'SAFE', Icons.shield_outlined),
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
                    child: const Text('Return to Dispatch Console'),
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
