import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/tts_service.dart';
import '../providers/ai_provider.dart';
import '../providers/journey_provider.dart';
import '../providers/settings_provider.dart';

class VoiceCompanionScreen extends ConsumerStatefulWidget {
  const VoiceCompanionScreen({super.key});

  @override
  ConsumerState<VoiceCompanionScreen> createState() => _VoiceCompanionScreenState();
}

class _VoiceCompanionScreenState extends ConsumerState<VoiceCompanionScreen> {
  final TtsService _ttsService = TtsService();
  final TextEditingController _replyController = TextEditingController();
  final TextEditingController _apiKeyDialogController = TextEditingController();

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
    _triggerNextDialogue(isCheckIn: false);

    _speechCycleTimer = Timer.periodic(const Duration(seconds: 12), (t) {
      if (mounted) {
        final isCheckIn = (t.tick % 2 == 0);
        _triggerNextDialogue(isCheckIn: isCheckIn);
      }
    });
  }

  Future<void> _triggerNextDialogue({required bool isCheckIn}) async {
    final aiService = ref.read(aiServiceProvider);
    final activeJourney = ref.read(journeyProvider);

    final line = await aiService.generateCompanionLine(
      isCheckInQuestion: isCheckIn,
      mode: activeJourney?.mode,
      destinationName: activeJourney?.destinationName,
    );

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

    final notifier = ref.read(journeyProvider.notifier);
    final activeJourney = ref.read(journeyProvider);

    if (activeJourney != null) {
      await notifier.submitCheckInResponse(reply);
    }

    const ack = "Glad to hear that. Stay safe!";
    setState(() {
      _currentDialogue = ack;
    });
    if (!_isMuted) {
      await _ttsService.speak(ack);
    }
  }

  void _showApiKeyDialog() {
    final currentKey = ref.read(settingsProvider).apiKey;
    _apiKeyDialogController.text = currentKey;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: Text('Gemini API Key Configuration', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste your Gemini API key to enable live AI dialogue generation & duress analysis.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _apiKeyDialogController,
              obscureText: true,
              style: GoogleFonts.ibmPlexMono(fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Gemini API Key',
                hintText: 'AIzaSy...',
                prefixIcon: Icon(Icons.vpn_key_outlined, size: 18),
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newKey = _apiKeyDialogController.text.trim();
              ref.read(settingsProvider.notifier).updateApiKey(newKey);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gemini API Key updated for Voice Companion.')),
              );
            },
            child: const Text('Save Key'),
          ),
        ],
      ),
    );
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
    _apiKeyDialogController.dispose();
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
    final settings = ref.watch(settingsProvider);
    final modeLabel = activeJourney?.mode.label ?? 'WALK';
    final hasApiKey = settings.apiKey.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF0E1A2B), // Deep Gekko Navy background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. Header & Call Status
              Column(
                children: [
                  const SizedBox(height: 12),
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

                  const SizedBox(height: 10),

                  // Gemini Telemetry Status Badge
                  GestureDetector(
                    onTap: _showApiKeyDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: hasApiKey
                            ? const Color(0xFF1E6B4F).withValues(alpha: 0.2)
                            : const Color(0xFF3B6E91).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: hasApiKey ? const Color(0xFF1E6B4F) : const Color(0xFF3B6E91),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 6,
                            color: hasApiKey ? const Color(0xFF1E6B4F) : const Color(0xFF3B6E91),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            hasApiKey
                                ? 'GEMINI 2.0 FLASH AI ENGINE: ACTIVE'
                                : 'GEMINI AI: LOCAL FALLBACK (TAP TO PASTE KEY)',
                            style: GoogleFonts.ibmPlexMono(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      color: const Color(0xFF14304D),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF3B6E91), width: 2.0),
                    ),
                    child: const Icon(Icons.record_voice_over_outlined, color: Colors.white, size: 42),
                  ),
                  const SizedBox(height: 14),
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
                  const SizedBox(height: 20),

                  // End Call Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
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
