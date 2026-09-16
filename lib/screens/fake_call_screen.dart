import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

    // Play TTS script
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
      backgroundColor: const Color(0xFF020617),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // Caller Avatar & Info
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF334155), width: 2),
              ),
              child: const Icon(Icons.person, size: 64, color: Colors.white70),
            ),

            const SizedBox(height: 20),

            const Text(
              'Mom (Safety Dispatch)',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
            ),

            const SizedBox(height: 8),

            Text(
              _isCallActive ? '$mins:$secs' : 'Incoming Gekko Safety Call...',
              style: TextStyle(
                fontSize: 16,
                color: _isCallActive ? Colors.green.shade400 : Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),

            if (_isCallActive) ...[
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                margin: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.graphic_eq, color: Colors.green, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Audio Playing via Browser TTS',
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '"$_callScript"',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 13, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ],

            const Spacer(),

            // Call Action Buttons
            Padding(
              padding: const EdgeInsets.only(bottom: 48),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (!_isCallActive) ...[
                    // Decline Button
                    _buildCallActionButton(
                      icon: Icons.call_end,
                      color: AppColors.sosRed,
                      label: 'Decline',
                      onTap: _endCall,
                    ),

                    // Accept Button
                    _buildCallActionButton(
                      icon: Icons.call,
                      color: Colors.green.shade600,
                      label: 'Accept',
                      onTap: _acceptCall,
                    ),
                  ] else ...[
                    // End Call Button
                    _buildCallActionButton(
                      icon: Icons.call_end,
                      color: AppColors.sosRed,
                      label: 'End Call',
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
          customBorder: const CircleBorder(),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
