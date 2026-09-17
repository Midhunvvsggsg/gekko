import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final TextEditingController _destinationController = TextEditingController();
  LatLng _selectedLatLng = LocationService.destinationSF1;
  int _expectedDurationMinutes = 20;

  bool _isBriefingLoading = false;
  String? _riskBriefingText;

  // Place Autocomplete State
  List<LocationSearchResult> _searchResults = [];
  bool _isSearchingLocation = false;

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

  void _onDestinationQueryChanged(String query) async {
    _fetchRiskBriefing();

    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearchingLocation = false;
      });
      return;
    }

    setState(() {
      _isSearchingLocation = true;
    });

    final results = await LocationService.searchPlaces(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearchingLocation = false;
      });
    }
  }

  void _onSelectSearchResult(LocationSearchResult result) {
    setState(() {
      _destinationController.text = result.description;
      _selectedLatLng = result.latLng;
      _searchResults = [];
    });
    _fetchRiskBriefing();
  }

  void _onStartJourney() {
    final destName = _destinationController.text.trim().isEmpty
        ? 'Union Square, San Francisco'
        : _destinationController.text.trim();

    ref.read(journeyProvider.notifier).startJourney(
          mode: _selectedMode,
          destinationName: destName,
          destinationLatLng: _selectedLatLng,
          expectedDuration: Duration(minutes: _expectedDurationMinutes),
        );
    context.go('/active');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'CONFIGURE DISPATCH PROFILE',
          style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Mode Selection Header
                Text(
                  '1. SELECT TRANSPORT ENGINE',
                  style: GoogleFonts.ibmPlexMono(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: 0.8),
                ),
                const SizedBox(height: 8),

                // Rectangular 4px max Mode Selector Chips
                SizedBox(
                  height: 84,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: JourneyModeConfig.defaultModes.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
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
                        borderRadius: BorderRadius.circular(4),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 120,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : AppColors.surface,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                              width: 1.0,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                mode.icon,
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                                size: 22,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                mode.label,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // 2. Destination Input & Live Place Autocomplete
                Text(
                  '2. TARGET DESTINATION & DURATION',
                  style: GoogleFonts.ibmPlexMono(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: 0.8),
                ),
                const SizedBox(height: 8),

                TextField(
                  controller: _destinationController,
                  onTap: () {
                    if (_destinationController.text.isNotEmpty) {
                      _destinationController.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: _destinationController.text.length,
                      );
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Destination Address or Landmark',
                    hintText: 'e.g. Union Square, San Francisco',
                    prefixIcon: const Icon(Icons.place_outlined, color: AppColors.textPrimary, size: 20),
                    suffixIcon: _isSearchingLocation
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            ),
                          )
                        : (_destinationController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _destinationController.clear();
                                  setState(() {
                                    _searchResults = [];
                                  });
                                },
                              )
                            : null),
                  ),
                  onChanged: _onDestinationQueryChanged,
                ),

                // Live Autocomplete Suggestions Overlay List
                if (_searchResults.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.primary, width: 1.2),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 18),
                          title: Text(
                            result.name,
                            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                          ),
                          subtitle: Text(
                            result.description,
                            style: GoogleFonts.ibmPlexMono(fontSize: 11, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _onSelectSearchResult(result),
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                // Preset Buttons
                Row(
                  children: [
                    Text('Presets: ', style: GoogleFonts.ibmPlexMono(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        children: _destinationPresets.map((preset) {
                          return OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            child: Text(preset['name'], style: GoogleFonts.ibmPlexMono(fontSize: 11, color: AppColors.textPrimary)),
                            onPressed: () {
                              setState(() {
                                _destinationController.text = preset['name'];
                                _selectedLatLng = preset['coords'];
                                _searchResults = [];
                              });
                              _fetchRiskBriefing();
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Expected Duration Chips
                Row(
                  children: [
                    Text('EXPECTED TIME: ', style: GoogleFonts.ibmPlexMono(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(width: 8),
                    Wrap(
                      spacing: 6,
                      children: [15, 20, 30, 45, 60].map((mins) {
                        final isSelected = _expectedDurationMinutes == mins;
                        return ChoiceChip(
                          label: Text('${mins}M'),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _expectedDurationMinutes = mins;
                              });
                            }
                          },
                          selectedColor: AppColors.primary,
                          labelStyle: GoogleFonts.ibmPlexMono(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 3. Mode-Specific AI Safety Behavior Summary Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.border, width: 1.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(_selectedMode.icon, color: AppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            '${_selectedMode.label.toUpperCase()} MONITORING SPECIFICATION',
                            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const Divider(height: 16, color: AppColors.border),
                      _buildProfileRow(
                        'Check-In Frequency',
                        'Every ${_selectedMode.checkInInterval.inMinutes} minutes (Conversational AI Prompt)',
                        Icons.timer_outlined,
                      ),
                      const SizedBox(height: 6),
                      _buildProfileRow(
                        'GPS Instrumentation',
                        _selectedMode.trustLiveGps ? 'Active (Alerts on off-route detours or stops)' : 'Checkpoint / Station Based',
                        Icons.gps_fixed_outlined,
                      ),
                      const SizedBox(height: 6),
                      _buildProfileRow(
                        'Primary Risk Trigger',
                        _selectedMode.primaryRiskSignal,
                        Icons.warning_amber_outlined,
                      ),
                      const SizedBox(height: 6),
                      _buildProfileRow(
                        'Escalation Grace Window',
                        '${_selectedMode.escalationGracePeriod.inMinutes} minutes before emergency network alert',
                        Icons.hourglass_bottom_outlined,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 4. Gemini AI Risk Briefing Card (Dispatch Console Dark Panel)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary, // #0E1A2B
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.bolt, color: AppColors.accentSecondary, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'AI PRE-JOURNEY RISK BRIEFING',
                            style: GoogleFonts.ibmPlexMono(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.8),
                          ),
                          const Spacer(),
                          if (_isBriefingLoading)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentSecondary),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _riskBriefingText ?? 'Generating location safety analysis...',
                        style: GoogleFonts.ibmPlexMono(color: AppColors.surfaceVariant, fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Start Journey Button (Rectangular 4px max, solid navy fill)
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _onStartJourney,
                    icon: const Icon(Icons.navigation_outlined, size: 18),
                    label: Text(
                      'START ${_selectedMode.label.toUpperCase()} JOURNEY',
                      style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.8),
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
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        SizedBox(
          width: 160,
          child: Text(
            label,
            style: GoogleFonts.ibmPlexMono(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
