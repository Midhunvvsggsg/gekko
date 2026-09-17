import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/check_in.dart';
import '../models/chat_message.dart';
import '../models/journey_mode_config.dart';
import '../providers/chat_companion_provider.dart';
import '../providers/journey_provider.dart';
import '../providers/settings_provider.dart';
import '../services/ai_service.dart';

class ChatCompanionScreen extends ConsumerStatefulWidget {
  const ChatCompanionScreen({super.key});

  @override
  ConsumerState<ChatCompanionScreen> createState() => _ChatCompanionScreenState();
}

class _ChatCompanionScreenState extends ConsumerState<ChatCompanionScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showInternals = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend([String? presetText]) {
    final text = presetText ?? _textController.text;
    if (text.trim().isEmpty) return;

    if (presetText == null) {
      _textController.clear();
    }

    final activeJourney = ref.read(journeyProvider);
    ref.read(chatCompanionProvider.notifier).sendMessage(text, activeJourney);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatCompanionProvider);
    final activeJourney = ref.watch(journeyProvider);
    final isDemoMode = ref.watch(settingsProvider.select((s) => s.isDemoMode));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI CHAT COMPANION',
              style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.8),
            ),
            Text(
              'GEMINI 2.0 FLASH CONVERSATIONAL SAFETY ENGINE',
              style: GoogleFonts.ibmPlexMono(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                const Icon(Icons.circle, size: 6, color: AppColors.safeGreen),
                const SizedBox(width: 4),
                Text(
                  'AI ACTIVE',
                  style: GoogleFonts.ibmPlexMono(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Active Journey Banner
            if (activeJourney != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceVariant,
                  border: Border(
                    bottom: BorderSide(color: AppColors.border, width: 1.0),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.navigation_outlined, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ACTIVE TRIP: ${activeJourney.mode.label.toUpperCase()} TO ${activeJourney.destinationName.toUpperCase()}',
                        style: GoogleFonts.ibmPlexMono(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            // Message List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: chatState.messages.length,
                itemBuilder: (context, index) {
                  final msg = chatState.messages[index];
                  return _buildMessageBubble(msg, activeJourney);
                },
              ),
            ),

            // Typing Indicator
            if (chatState.isSending)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Gemini AI is analyzing & typing response...',
                      style: GoogleFonts.ibmPlexMono(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

            // Demo Mode Raw JSON Inspector Panel
            if (isDemoMode && chatState.messages.isNotEmpty) ...[
              InkWell(
                onTap: () {
                  setState(() {
                    _showInternals = !_showInternals;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  color: AppColors.surfaceVariant,
                  child: Row(
                    children: [
                      const Icon(Icons.code_outlined, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'AI TELEMETRY JSON (GEMINI CLASSIFICATION)',
                        style: GoogleFonts.ibmPlexMono(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                      const Spacer(),
                      Icon(_showInternals ? Icons.expand_less : Icons.expand_more, size: 16, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
              if (_showInternals && chatState.messages.last.rawJson != null)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    color: AppColors.textPrimary,
                    child: SingleChildScrollView(
                      child: SelectableText(
                        chatState.messages.last.rawJson!,
                        style: GoogleFonts.ibmPlexMono(fontSize: 10, color: Colors.greenAccent),
                      ),
                    ),
                  ),
                ),
            ],

            // Quick Question Chips
            Container(
              height: 42,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _buildQuickChip('Is this route safe?'),
                  _buildQuickChip('I feel uncomfortable'),
                  _buildQuickChip('Someone is behind me'),
                  _buildQuickChip('How far to destination?'),
                  _buildQuickChip('Keep me company'),
                ],
              ),
            ),

            // Text Input Field Bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1.0),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      enabled: !chatState.isSending,
                      style: GoogleFonts.ibmPlexSans(fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Talk to AI Safety Companion...',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                    onPressed: chatState.isSending ? null : () => _handleSend(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(
          text,
          style: GoogleFonts.ibmPlexSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.border, width: 1.0),
        onPressed: () => _handleSend(text),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, dynamic activeJourney) {
    final isUser = msg.sender == 'user';

    Color borderAccentColor = AppColors.primary;
    if (msg.safetyStatus == CheckInStatus.uncertain) {
      borderAccentColor = AppColors.warningAmber;
    } else if (msg.safetyStatus == CheckInStatus.concerning) {
      borderAccentColor = AppColors.sosRed;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.border, width: 1.0),
                  ),
                  child: const Icon(Icons.shield_outlined, size: 14, color: AppColors.primary),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                isUser ? 'YOU' : 'GEKKO AI COMPANION',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isUser ? AppColors.textSecondary : AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                style: GoogleFonts.ibmPlexMono(fontSize: 9, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 4),

          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(4),
                border: isUser
                    ? null
                    : Border(
                        left: BorderSide(color: borderAccentColor, width: 4.0),
                        top: const BorderSide(color: AppColors.border, width: 1.0),
                        right: const BorderSide(color: AppColors.border, width: 1.0),
                        bottom: const BorderSide(color: AppColors.border, width: 1.0),
                      ),
              ),
              child: Text(
                msg.text,
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 13,
                  height: 1.4,
                  color: isUser ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ),

          // Safety Actions Trigger Card if uncertain or concerning
          if (!isUser && msg.safetyStatus != null && msg.safetyStatus != CheckInStatus.safe) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: borderAccentColor, width: 1.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        msg.safetyStatus == CheckInStatus.concerning ? Icons.warning_amber_rounded : Icons.info_outlined,
                        size: 16,
                        color: borderAccentColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        msg.safetyStatus == CheckInStatus.concerning
                            ? 'HIGH SAFETY CONCERN DETECTED'
                            : 'HEIGHTENED VIGILANCE RECOMMENDED',
                        style: GoogleFonts.ibmPlexMono(fontSize: 10, fontWeight: FontWeight.w700, color: borderAccentColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    msg.rationale ?? AIService.getModeSafetyGuidance(activeJourney?.mode ?? JourneyModeConfig.defaultModes.first),
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.sosRed,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        onPressed: () {
                          if (activeJourney != null) {
                            ref.read(journeyProvider.notifier).triggerSOS(triggerSource: 'AI Chat Companion Safety Alert');
                            context.push('/sos');
                          } else {
                            context.push('/settings');
                          }
                        },
                        icon: const Icon(Icons.warning_amber, size: 14),
                        label: Text('DISPATCH SOS ALARM', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.push('/fake-call'),
                        icon: const Icon(Icons.phone_callback_outlined, size: 14),
                        label: Text('FAKE CALL EXIT', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
