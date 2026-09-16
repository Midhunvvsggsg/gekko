import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_colors.dart';
import '../models/journey_mode_config.dart';
import '../services/location_service.dart';
import '../providers/journey_provider.dart';
import '../providers/ai_provider.dart';

class JourneySetupScreen extends ConsumerStatefulWidget {
  const JourneySetupScreen({super.key});

  @override
  ConsumerState<JourneySetupScreen> createState() => _JourneySetupScreenState();
}

class _JourneySetupScreenState extends ConsumerState<JourneySetupScreen> {
  JourneyModeConfig _selectedMode = JourneyModeConfig.defaultModes[0]; // Walking
  final TextEditingController _destinationController = TextEditingController(text: 'Union Square, San Francisco');
  LatLng _selectedLatLng = LocationService.destinationSF1;
  int _expectedDurationMinutes = 20;

  bool _isBriefingLoading = false;
  String? _riskBriefingText;

  final List<Map<String, dynamic>> _destinationPresets = [
    {'name': 'Union Square, SF', 'coords': LocationService.destinationSF1},
    {'name': 'Mission District, SF', 'coords': LocationService.destinationSF2},
    {'name': 'Embarcadero Pier, SF', 'coords': LocationService.destinationSF3},
  ];

  @override
  void initState() {
    super.initState();
    _fetchRiskBriefing();
  }

  Future<void> _fetchRiskBriefing() async {
    setState(() {
      _isBriefingLoading = true;
    });

    try {
      final aiService = ref.read(aiServiceProvider);
      final briefing = await aiService.generateRiskBriefing(
        _destinationController.text,
        'Evening',
        _selectedMode,
      );
      if (mounted) {
        setState(() {
          _riskBriefingText = briefing;
          _isBriefingLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isBriefingLoading = false;
        });
      }
    }
  }

  void _onStartJourney() {
    ref.read(journeyProvider.notifier).startJourney(
          mode: _selectedMode,
          destinationName: _destinationController.text,
          destinationLatLng: _selectedLatLng,
          expectedDuration: Duration(minutes: _expectedDurationMinutes),
        );
    context.go('/active');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Safety Journey'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Mode Selection Header
                const Text(
                  '1. Select Transport Mode',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),

                // Horizontal Mode Selector Chips
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: JourneyModeConfig.defaultModes.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final mode = JourneyModeConfig.defaultModes[index];
                      final isSelected = mode.id == _selectedMode.id;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedMode = mode;
                          });
                          _fetchRiskBriefing();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 120,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryContainer : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                mode.icon,
                                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                size: 28,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                mode.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // 2. Destination Input & Presets
                const Text(
                  '2. Destination & Duration',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _destinationController,
                  decoration: const InputDecoration(
                    labelText: 'Destination Name or Address',
                    prefixIcon: Icon(Icons.place_outlined, color: AppColors.primary),
                  ),
                  onChanged: (_) => _fetchRiskBriefing(),
                ),

                const SizedBox(height: 10),

                // Preset Buttons
                Row(
                  children: [
                    const Text('Quick Select: ', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        children: _destinationPresets.map((preset) {
                          return ActionChip(
                            label: Text(preset['name'], style: const TextStyle(fontSize: 12)),
                            onPressed: () {
                              setState(() {
                                _destinationController.text = preset['name'];
                                _selectedLatLng = preset['coords'];
                              });
                              _fetchRiskBriefing();
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Expected Duration Chips
                Row(
                  children: [
                    const Text('Expected Duration: ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Wrap(
                      spacing: 8,
                      children: [15, 20, 30, 45, 60].map((mins) {
                        final isSelected = _expectedDurationMinutes == mins;
                        return ChoiceChip(
                          label: Text('$mins mins'),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _expectedDurationMinutes = mins;
                              });
                            }
                          },
                          selectedColor: AppColors.primaryContainer,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 3. Mode-Specific AI Safety Behavior Summary Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(_selectedMode.icon, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Text(
                            '${_selectedMode.label} Monitoring Profile',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      _buildProfileRow(
                        'Check-In Frequency',
                        'Every ${_selectedMode.checkInInterval.inMinutes} minutes (AI Conversational Prompt)',
                        Icons.timer_outlined,
                      ),
                      const SizedBox(height: 8),
                      _buildProfileRow(
                        'GPS Deviation Monitoring',
                        _selectedMode.trustLiveGps ? 'Active (Alerts on unexpected stops or detours)' : 'Station / Checkpoint Based',
                        Icons.gps_fixed_outlined,
                      ),
                      const SizedBox(height: 8),
                      _buildProfileRow(
                        'Primary Risk Signal',
                        _selectedMode.primaryRiskSignal,
                        Icons.warning_amber_rounded,
                      ),
                      const SizedBox(height: 8),
                      _buildProfileRow(
                        'Escalation Grace Period',
                        '${_selectedMode.escalationGracePeriod.inMinutes} minutes before emergency contact alert',
                        Icons.hourglass_bottom_rounded,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 4. Gemini AI Risk Briefing Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Gemini AI Pre-Journey Risk Briefing',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const Spacer(),
                          if (_isBriefingLoading)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _riskBriefingText ?? 'Generating location safety analysis...',
                        style: TextStyle(color: Colors.grey.shade300, fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Start Journey Button
                SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _onStartJourney,
                    icon: const Icon(Icons.shield_rounded),
                    label: Text(
                      'Confirm & Start ${_selectedMode.label} Journey',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  Widget _buildProfileRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 8),
        SizedBox(
          width: 160,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
