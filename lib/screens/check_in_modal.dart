import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

      // Brief delay to let user see rationale before modal closes/escalates
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
        : "Gekko Safety Check: How is your journey going?";

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Top Bar Indicator
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.shield_outlined, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI SAFETY CHECK-IN',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 0.8),
                      ),
                      Text(
                        'Confirm Your Safety Status',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // AI Generated Prompt Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      promptText,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Quick Preset Response Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: const Text('All good, walking safely 👍'),
                  onPressed: () {
                    _responseController.text = 'All good, walking safely';
                  },
                ),
                ActionChip(
                  label: const Text('On target, almost there 🎯'),
                  onPressed: () {
                    _responseController.text = 'On target, almost there';
                  },
                ),
                ActionChip(
                  label: const Text('Feeling uncomfortable ⚠️'),
                  backgroundColor: AppColors.uncertainYellowBg,
                  onPressed: () {
                    _responseController.text = 'Feeling a bit uncomfortable with someone behind me';
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Response Input Field + Voice Mic Button
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _responseController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: _isVoiceRecording ? 'Listening to voice...' : 'Type response or tap mic...',
                      suffixIcon: _responseController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => _responseController.clear(),
                            )
                          : null,
                    ),
                    onSubmitted: (_) => _submitResponse(),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  onPressed: _toggleVoiceRecording,
                  style: IconButton.styleFrom(
                    backgroundColor: _isVoiceRecording ? AppColors.sosRed : AppColors.primary,
                    padding: const EdgeInsets.all(14),
                  ),
                  icon: Icon(
                    _isVoiceRecording ? Icons.mic_off : Icons.mic,
                    color: Colors.white,
                  ),
                ),
              ],
            ),

            // Voice Recording Wave Jitter Indicator
            if (_isVoiceRecording) ...[
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.graphic_eq, color: AppColors.sosRed, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Listening... Speak naturally into microphone',
                    style: TextStyle(fontSize: 12, color: AppColors.sosRed, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Classification Preview Badge (if evaluated)
            if (_previewClassification != null) ...[
              _buildClassificationCard(_previewClassification!),
              const SizedBox(height: 16),
            ],

            // Submit Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitResponse,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Confirm Check-In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassificationCard(CheckInClassification classification) {
    Color bg;
    Color border;
    Color text;
    String title;

    switch (classification.status) {
      case CheckInStatus.safe:
        bg = AppColors.safeGreenBg;
        border = AppColors.safeGreenBorder;
        text = AppColors.safeGreen;
        title = 'STATUS: SAFE';
        break;
      case CheckInStatus.uncertain:
        bg = AppColors.uncertainYellowBg;
        border = AppColors.uncertainYellowBorder;
        text = AppColors.uncertainYellow;
        title = 'STATUS: UNCERTAIN';
        break;
      case CheckInStatus.concerning:
        bg = AppColors.sosRedBg;
        border = AppColors.sosRedBorder;
        text = AppColors.sosRed;
        title = classification.duressDetected ? 'SILENT DURESS DETECTED' : 'STATUS: CONCERNING';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: text, letterSpacing: 0.8),
          ),
          const SizedBox(height: 4),
          Text(
            classification.rationale,
            style: TextStyle(fontSize: 13, color: text, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
