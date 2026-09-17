import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/check_in.dart';
import '../providers/journey_provider.dart';
import '../providers/settings_provider.dart';
import '../services/speech_service.dart';

class CheckInModal extends ConsumerStatefulWidget {
  const CheckInModal({super.key});

  @override
  ConsumerState<CheckInModal> createState() => _CheckInModalState();
}

class _CheckInModalState extends ConsumerState<CheckInModal> {
  final TextEditingController _responseController = TextEditingController();
  final SpeechService _speechService = SpeechService();

  bool _isVoiceRecording = false;
  bool _isSubmitting = false;
  String? _submittedUserResponse;
  CheckInClassification? _classificationResult;
  bool _showInternals = false;

  @override
  void dispose() {
    _responseController.dispose();
    _speechService.stopListening();
    super.dispose();
  }

  void _toggleVoiceRecording() {
    if (_isVoiceRecording) {
      _speechService.stopListening();
      setState(() {
        _isVoiceRecording = false;
      });
    } else {
      setState(() {
        _isVoiceRecording = true;
      });

      _speechService.startListening(
        onResult: (text) {
          if (mounted) {
            setState(() {
              _responseController.text = text;
            });
          }
        },
        onError: () {
          if (mounted) {
            setState(() {
              _isVoiceRecording = false;
            });
          }
        },
      );
    }
  }

  Future<void> _submitResponse() async {
    final text = _responseController.text.trim();
    if (text.isEmpty || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _submittedUserResponse = text;
    });

    final notifier = ref.read(journeyProvider.notifier);
    final result = await notifier.submitCheckInResponse(
      text,
      isVoice: _isVoiceRecording,
    );

    if (mounted) {
      setState(() {
        _classificationResult = result;
        _isSubmitting = false;
      });

      // Auto dismiss modal or transition to escalation if CONCERNING / DURESS
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final journey = ref.watch(journeyProvider);
    final isDemoMode = ref.watch(settingsProvider.select((s) => s.isDemoMode));

    final promptText = journey?.checkIns.isNotEmpty == true
        ? journey!.checkIns.last.promptText
        : "Gekko Safety Instrumentation: Confirm your current status.";

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 650),
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(4)), // Rectangular 4px max
          border: Border(
            top: BorderSide(color: AppColors.primary, width: 3.0),
            left: BorderSide(color: AppColors.border, width: 1.0),
            right: BorderSide(color: AppColors.border, width: 1.0),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.border, width: 1.0),
                    ),
                    child: const Icon(Icons.shield_outlined, color: AppColors.textPrimary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI SAFETY CHECK-IN',
                          style: GoogleFonts.ibmPlexMono(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 0.8),
                        ),
                        Text(
                          'Conversational Verification',
                          style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  if (isDemoMode)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.border, width: 1.0),
                      ),
                      child: Text(
                        'DEMO MODE',
                        style: GoogleFonts.ibmPlexMono(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.warningAmber),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Chat Bubble 1: Gemini Generated System Prompt (Left Aligned)
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary, // #14304D Deep Navy
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt, color: Colors.white70, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'GEKKO SAFETY INSTRUMENTATION',
                            style: GoogleFonts.ibmPlexMono(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white70, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        promptText,
                        style: GoogleFonts.ibmPlexSans(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),

              // Chat Bubble 2: User Submitted Response (Right Aligned)
              if (_submittedUserResponse != null) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.border, width: 1.0),
                    ),
                    child: Text(
                      _submittedUserResponse!,
                      style: GoogleFonts.ibmPlexSans(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // Input Field & Action Buttons (Hidden after submission)
              if (_submittedUserResponse == null) ...[
                // Preset Response Chips
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                      onPressed: () => _responseController.text = 'All good, walking safely',
                      child: Text('All good, walking safely', style: GoogleFonts.ibmPlexMono(fontSize: 11)),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                      onPressed: () => _responseController.text = 'On target, almost there',
                      child: Text('On target, almost there', style: GoogleFonts.ibmPlexMono(fontSize: 11)),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        side: const BorderSide(color: AppColors.warningAmber, width: 1.0),
                      ),
                      onPressed: () => _responseController.text = 'Feeling a bit uncomfortable, someone behind me',
                      child: Text('Feeling uncomfortable ⚠️', style: GoogleFonts.ibmPlexMono(fontSize: 11, color: AppColors.warningAmber)),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // TextField + Voice Dictation
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _responseController,
                        autofocus: true,
                        style: GoogleFonts.ibmPlexSans(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: _isVoiceRecording ? 'Listening...' : 'Type reply or tap mic...',
                          suffixIcon: _responseController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () => _responseController.clear(),
                                )
                              : null,
                        ),
                        onSubmitted: (_) => _submitResponse(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _toggleVoiceRecording,
                      style: IconButton.styleFrom(
                        backgroundColor: _isVoiceRecording ? AppColors.sosRed : AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        padding: const EdgeInsets.all(12),
                      ),
                      icon: Icon(
                        _isVoiceRecording ? Icons.mic_off : Icons.mic,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Submit Button
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitResponse,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Confirm Response Payload'),
                  ),
                ),
              ],

              // Classification Result Card (Left Accent Stripe rectangular tag)
              if (_classificationResult != null) ...[
                const SizedBox(height: 16),
                _buildClassificationCard(_classificationResult!),

                // Collapsible AI Internals Panel (Judge / Demo Mode)
                if (isDemoMode && _classificationResult!.rawJson != null) ...[
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
                          const Icon(Icons.code_outlined, size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            'AI INTERNALS (RAW GEMINI JSON)',
                            style: GoogleFonts.ibmPlexMono(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary),
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
                        _classificationResult!.rawJson!,
                        style: GoogleFonts.ibmPlexMono(fontSize: 10, color: Colors.greenAccent, height: 1.4),
                      ),
                    ),
                  ],
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassificationCard(CheckInClassification classification) {
    Color borderAccent;
    String title;

    // RULE: Silent duress displays SAFE tag on screen to avoid visual alert difference
    if (classification.duressDetected) {
      borderAccent = AppColors.safeGreen;
      title = 'SAFE';
    } else {
      switch (classification.status) {
        case CheckInStatus.safe:
          borderAccent = AppColors.safeGreen;
          title = 'SAFE';
          break;
        case CheckInStatus.uncertain:
          borderAccent = AppColors.warningAmber;
          title = 'UNCERTAIN';
          break;
        case CheckInStatus.concerning:
          borderAccent = AppColors.sosRed;
          title = 'CONCERNING';
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          left: BorderSide(color: borderAccent, width: 4.0),
          top: const BorderSide(color: AppColors.border, width: 1.0),
          right: const BorderSide(color: AppColors.border, width: 1.0),
          bottom: const BorderSide(color: AppColors.border, width: 1.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: borderAccent, width: 1.0),
                ),
                child: Text(
                  title,
                  style: GoogleFonts.ibmPlexMono(fontWeight: FontWeight.w700, fontSize: 11, color: borderAccent, letterSpacing: 0.8),
                ),
              ),
              const Spacer(),
              Text(
                'CLASSIFIED BY GEMINI AI',
                style: GoogleFonts.ibmPlexMono(fontSize: 9, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            classification.rationale,
            style: GoogleFonts.ibmPlexMono(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500, height: 1.4),
          ),
        ],
      ),
    );
  }
}
