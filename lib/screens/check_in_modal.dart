import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/check_in.dart';
import '../providers/journey_provider.dart';
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
  CheckInClassification? _previewClassification;

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
    if (text.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    final notifier = ref.read(journeyProvider.notifier);
    final result = await notifier.submitCheckInResponse(
      text,
      isVoice: _isVoiceRecording,
    );

    if (mounted) {
      setState(() {
        _previewClassification = result;
        _isSubmitting = false;
      });

      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final journey = ref.watch(journeyProvider);
    final promptText = journey?.checkIns.isNotEmpty == true
        ? journey!.checkIns.last.promptText
        : "Gekko Safety Instrumentation: Confirm your status.";

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(4)), // Rectangular 4px max
          border: Border(
            top: BorderSide(color: AppColors.primary, width: 2.0),
            left: BorderSide(color: AppColors.border, width: 1.0),
            right: BorderSide(color: AppColors.border, width: 1.0),
          ),
        ),
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
                        'Confirm Safety Instrumentation',
                        style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // AI Prompt Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.border, width: 1.0),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.bolt, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      promptText,
                      style: GoogleFonts.ibmPlexSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Preset Response Tags (Rectangular 4px max)
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
                  onPressed: () => _responseController.text = 'Feeling a bit uncomfortable with someone behind me',
                  child: Text('Feeling uncomfortable ⚠️', style: GoogleFonts.ibmPlexMono(fontSize: 11, color: AppColors.warningAmber)),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Input Field + Voice Button
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _responseController,
                    autofocus: true,
                    style: GoogleFonts.ibmPlexSans(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: _isVoiceRecording ? 'Listening...' : 'Type response or tap mic...',
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

            if (_isVoiceRecording) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.graphic_eq, color: AppColors.sosRed, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Listening... Speak naturally into microphone',
                    style: GoogleFonts.ibmPlexMono(fontSize: 11, color: AppColors.sosRed, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 14),

            // Classification Tag (Console Rectangular Tag with Left Border Accent)
            if (_previewClassification != null) ...[
              _buildClassificationCard(_previewClassification!),
              const SizedBox(height: 14),
            ],

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
                    : const Text('Confirm Status Response'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassificationCard(CheckInClassification classification) {
    Color borderAccent;
    Color bg;
    String title;

    switch (classification.status) {
      case CheckInStatus.safe:
        borderAccent = AppColors.safeGreen;
        bg = AppColors.safeGreenBg;
        title = 'STATUS // SAFE';
        break;
      case CheckInStatus.uncertain:
        borderAccent = AppColors.warningAmber;
        bg = AppColors.warningBg;
        title = 'STATUS // UNCERTAIN';
        break;
      case CheckInStatus.concerning:
        borderAccent = AppColors.sosRed;
        bg = AppColors.sosRedBg;
        title = classification.duressDetected ? 'SILENT DURESS DETECTED' : 'STATUS // CONCERNING';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
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
          Text(
            title,
            style: GoogleFonts.ibmPlexMono(fontWeight: FontWeight.w700, fontSize: 11, color: borderAccent, letterSpacing: 0.8),
          ),
          const SizedBox(height: 2),
          Text(
            classification.rationale,
            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
