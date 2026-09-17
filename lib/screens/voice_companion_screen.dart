import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/tts_service.dart';
import '../providers/ai_provider.dart';
import '../providers/journey_provider.dart';

class VoiceCompanionScreen extends ConsumerStatefulWidget {
  const VoiceCompanionScreen({super.key});

  @override
  ConsumerState<VoiceCompanionScreen> createState() => _VoiceCompanionScreenState();
}

class _VoiceCompanionScreenState extends ConsumerState<VoiceCompanionScreen> {
  final TtsService _ttsService = TtsService();
  final TextEditingController _replyController = TextEditingController();

  Timer? _callTimer;
  Timer? _speechCycleTimer;

  int _callDurationSeconds = 0;
  String _currentDialogue = "Connecting to Voice Companion...";
  bool _isMuted = false;
  bool _isSpeaker = true;
  bool _isCheckInPending = false;

  @override
  void initState() {
    super.initState();
    _startCallTimer();
    _startDialogueLoop();
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() {
          _callDurationSeconds++;
        });
      }
    });
  }

  void _startDialogueLoop() {
    // Speak initial line
    _triggerNextDialogue(isCheckIn: false);

    // Speak next line every 12 seconds
    _speechCycleTimer = Timer.periodic(const Duration(seconds: 12), (t) {
      if (mounted) {
        final isCheckIn = (t.tick % 2 == 0);
        _triggerNextDialogue(isCheckIn: isCheckIn);
      }
    });
  }

  Future<void> _triggerNextDialogue({required bool isCheckIn}) async {
    final aiService = ref.read(aiServiceProvider);
    final line = await aiService.generateCompanionLine(isCheckInQuestion: isCheckIn);

    if (mounted) {
      setState(() {
        _currentDialogue = line;
        _isCheckInPending = isCheckIn;
      });

      if (!_isMuted) {
        await _ttsService.speak(line);
      }
    }
  }

  Future<void> _submitReply() async {
    final reply = _replyController.text.trim();
    if (reply.isEmpty) return;

    _replyController.clear();
    setState(() {
      _isCheckInPending = false;
    });

    // Pass response to journey check-in pipeline
    final notifier = ref.read(journeyProvider.notifier);
    final activeJourney = ref.read(journeyProvider);

    if (activeJourney != null) {
      await notifier.submitCheckInResponse(reply);
    }

    // Acknowledge reply with TTS
    const ack = "Glad to hear that. Stay safe!";
    setState(() {
      _currentDialogue = ack;
    });
    if (!_isMuted) {
      await _ttsService.speak(ack);
    }
  }

  void _endCall() {
    _ttsService.stop();
    _callTimer?.cancel();
    _speechCycleTimer?.cancel();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _ttsService.stop();
    _callTimer?.cancel();
    _speechCycleTimer?.cancel();
    _replyController.dispose();
    super.dispose();
  }

  String _formatTimer(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final activeJourney = ref.watch(journeyProvider);
    final modeLabel = activeJourney?.mode.label ?? 'WALK';

    return Scaffold(
      backgroundColor: const Color(0xFF0E1A2B), // Deep Gekko Navy background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. Header & Call Status
              Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white24, width: 1.0),
                    ),
                    child: Text(
                      'GEKKO DETERRENT VOICE COMPANION • $modeLabel',
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFF14304D),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF3B6E91), width: 2.0),
                    ),
                    child: const Icon(Icons.record_voice_over_outlined, color: Colors.white, size: 44),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Mom (AI Voice Companion)',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimer(_callDurationSeconds),
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3B6E91),
                    ),
                  ),
                ],
              ),

              // 2. Dialogue & Check-In Input Container
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12, width: 1.0),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isCheckInPending ? Icons.shield : Icons.volume_up,
                          size: 16,
                          color: _isCheckInPending ? const Color(0xFFC77A1F) : const Color(0xFF3B6E91),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isCheckInPending ? 'EMBEDDED AI SAFETY CHECK-IN' : 'ONGOING CALL COMPANION DIALOGUE',
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _isCheckInPending ? const Color(0xFFC77A1F) : Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '"$_currentDialogue"',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                    if (_isCheckInPending) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _replyController,
                              style: GoogleFonts.ibmPlexSans(fontSize: 13, color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Reply to Mom (e.g. Almost home!)...',
                                hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.1),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onSubmitted: (_) => _submitReply(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _submitReply,
                            icon: const Icon(Icons.send_rounded, color: Colors.white),
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFF14304D),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // 3. Call Controls (Mute, Speaker, End Call)
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isMuted = !_isMuted;
                            if (_isMuted) _ttsService.stop();
                          });
                        },
                        icon: Icon(_isMuted ? Icons.mic_off : Icons.mic, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isSpeaker = !_isSpeaker;
                          });
                        },
                        icon: Icon(_isSpeaker ? Icons.volume_up : Icons.phone_in_talk, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // End Call Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _endCall,
                      icon: const Icon(Icons.call_end, color: Colors.white),
                      label: Text(
                        'END VOICE COMPANION CALL',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB3261E), // Deep Red
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
