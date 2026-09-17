import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/speech_service.dart';

class FakeCallScreen extends StatefulWidget {
  const FakeCallScreen({super.key});

  @override
  State<FakeCallScreen> createState() => _FakeCallScreenState();
}

class _FakeCallScreenState extends State<FakeCallScreen> {
  bool _isCallActive = false;
  int _callDurationSeconds = 0;
  Timer? _durationTimer;

  static const String _callScript =
      "Hey sweetie! I'm waiting outside in the car nearby right now. "
      "Can you come out and meet me by the entrance in two minutes? Let's head home together.";

  @override
  void dispose() {
    _durationTimer?.cancel();
    SpeechService.stopSpeaking();
    super.dispose();
  }

  void _acceptCall() {
    setState(() {
      _isCallActive = true;
      _callDurationSeconds = 0;
    });

    _durationTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() {
          _callDurationSeconds++;
        });
      }
    });

    SpeechService.speak(_callScript);
  }

  void _endCall() {
    _durationTimer?.cancel();
    SpeechService.stopSpeaking();
    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mins = (_callDurationSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (_callDurationSeconds % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: AppColors.textPrimary, // #0E1A2B Deep Navy Charcoal
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // Caller Avatar & Info
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.border, width: 1.0),
              ),
              child: const Icon(Icons.person_outlined, size: 48, color: Colors.white70),
            ),

            const SizedBox(height: 16),

            Text(
              'Mom (Safety Dispatch)',
              style: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
            ),

            const SizedBox(height: 6),

            Text(
              _isCallActive ? '$mins:$secs' : 'INCOMING EMERGENCY EXIT CALL...',
              style: GoogleFonts.ibmPlexMono(
                fontSize: 13,
                color: _isCallActive ? AppColors.safeGreenBorder : Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),

            if (_isCallActive) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white24, width: 1.0),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.graphic_eq, color: AppColors.safeGreenBorder, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Audio Telemetry Active',
                          style: GoogleFonts.ibmPlexMono(color: AppColors.safeGreenBorder, fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '"$_callScript"',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.ibmPlexMono(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],

            const Spacer(),

            // Call Action Buttons (Rectangular 4px max)
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (!_isCallActive) ...[
                    // Decline Button
                    _buildCallActionButton(
                      icon: Icons.call_end_outlined,
                      color: AppColors.sosRed,
                      label: 'DECLINE',
                      onTap: _endCall,
                    ),

                    // Accept Button
                    _buildCallActionButton(
                      icon: Icons.call_outlined,
                      color: AppColors.safeGreen,
                      label: 'ACCEPT',
                      onTap: _acceptCall,
                    ),
                  ] else ...[
                    // End Call Button
                    _buildCallActionButton(
                      icon: Icons.call_end_outlined,
                      color: AppColors.sosRed,
                      label: 'END CALL',
                      onTap: _endCall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.ibmPlexMono(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
