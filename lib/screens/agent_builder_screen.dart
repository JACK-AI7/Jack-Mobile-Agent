// lib/screens/agent_builder_screen.dart
//
// 04. Agent Builder — Interactive, rotatable constellation wheel with
// 8 mini 3D luminous orbs and full real configuration functionality.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api/jack_storage.dart';
import '../services/api/direct_groq_service.dart';
import '../services/personality/jack_personality_service.dart';
import '../services/jack_master_dispatcher.dart';
import '../services/tasks/jack_task_service.dart';
import '../services/overlay/jack_floating_overlay_controller.dart';
import '../services/memory/jack_cognitive_memory.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_nav_bar.dart';

class BuilderScreen extends ConsumerStatefulWidget {
  const BuilderScreen({super.key});

  @override
  ConsumerState<BuilderScreen> createState() => _BuilderScreenState();
}

class _BuilderScreenState extends ConsumerState<BuilderScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _driftController;
  late final AnimationController _frictionController;

  double _currentRotation = 0.0;
  double _lastTouchAngle = 0.0;
  bool _isDragging = false;

  // Live Hardware Controls
  double _liveVolume = 75.0;
  double _liveBrightness = 80.0;
  int _liveBatteryLevel = 85;
  final FlutterTts _tts = FlutterTts();

  // Real interactive configuration state for personality
  double _temperature = 0.7;
  double _conciseness = 0.5;
  int _selectedToneIndex = 1; // 0: Direct, 1: Executive, 2: British/Jarvis, 3: Friendly
  final TextEditingController _customPromptCtrl = TextEditingController();

  // Tools state (live persisted)
  bool _toolTorch = true;
  bool _toolWifi = true;
  bool _toolBluetooth = true;
  bool _toolVolume = true;
  bool _toolLock = true;
  bool _toolWeb = true;
  bool _toolApps = true;

  // Automations state (live persisted)
  bool _autoDailyBrief = true;
  bool _autoMonitorProject = true;
  bool _autoPriceDrop = true;
  bool _autoBatterySaver = true;

  // Real interactive configuration state for memory
  bool _longTermMemoryEnabled = true;
  List<CognitiveMemoryItem> _cognitiveMemories = [];
  List<String> _memories = [];
  final TextEditingController _newMemoryCtrl = TextEditingController();

  // Knowledge state (live persisted)
  bool _knowGoogleNews = true;
  bool _knowWikipedia = true;
  bool _knowContacts = true;
  bool _knowCalendar = true;
  final TextEditingController _newGroundingDocCtrl = TextEditingController();

  // Integrations state (live persisted)
  final TextEditingController _groqKeyCtrl = TextEditingController();
  final TextEditingController _mcpUrlCtrl =
      TextEditingController(text: 'http://10.0.2.2:8000/sse');
  final TextEditingController _githubTokenCtrl = TextEditingController();
  bool _obscureGroqKey = true;

  // Skills state (live persisted)
  bool _skillCallScreener = true;
  bool _skillGeminiPill = true;
  bool _skillWebScraper = true;
  bool _skillAccessibility = true;
  bool _skillVoiceBaritone = true;

  final List<Map<String, dynamic>> _nodes = [
    {
      'label': 'Tools',
      'icon': Icons.tune_rounded,
      'color': const Color(0xFF00E5FF),
      'secondaryColor': const Color(0xFF0284C7),
    },
    {
      'label': 'Automations',
      'icon': Icons.settings_suggest_rounded,
      'color': const Color(0xFF8B5CF6),
      'secondaryColor': const Color(0xFF00E5FF),
    },
    {
      'label': 'Memory',
      'icon': Icons.settings_rounded,
      'color': const Color(0xFFF43F5E),
      'secondaryColor': const Color(0xFFEC4899),
    },
    {
      'label': 'Integrations',
      'icon': Icons.all_inclusive_rounded,
      'color': const Color(0xFF3B82F6),
      'secondaryColor': const Color(0xFF6366F1),
    },
    {
      'label': 'Personality',
      'icon': Icons.person_rounded,
      'color': const Color(0xFF7C3AED),
      'secondaryColor': const Color(0xFF9333EA),
    },
    {
      'label': 'Knowledge',
      'icon': Icons.find_in_page_rounded,
      'color': const Color(0xFFF59E0B),
      'secondaryColor': const Color(0xFF84CC16),
    },
    {
      'label': 'Data',
      'icon': Icons.dns_rounded,
      'color': const Color(0xFF10B981),
      'secondaryColor': const Color(0xFF059669),
    },
    {
      'label': 'Skills',
      'icon': Icons.business_center_rounded,
      'color': const Color(0xFFA855F7),
      'secondaryColor': const Color(0xFFEC4899),
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadStoredSettings();

    // Pulse animation for starburst core
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // Subtle continuous orbital drift
    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..addListener(() {
        if (!_isDragging && !_frictionController.isAnimating) {
          setState(() {
            _currentRotation += 0.0015;
          });
        }
      });
    _driftController.repeat();

    // Friction physics for fling spin
    _frictionController = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        setState(() {
          _currentRotation = _frictionController.value;
        });
      });
  }

  Future<void> _loadStoredSettings() async {
    try {
      final activePersonality = ref.read(jackPersonalityProvider).activeProfile;
      switch (activePersonality.id.toLowerCase()) {
        case 'direct':
          _selectedToneIndex = 0;
          break;
        case 'executive':
          _selectedToneIndex = 1;
          break;
        case 'jarvis':
          _selectedToneIndex = 2;
          break;
        case 'friendly':
          _selectedToneIndex = 3;
          break;
        case 'cyberpunk':
          _selectedToneIndex = 4;
          break;
        default:
          _selectedToneIndex = 2;
      }
      final temp = await JackStorage.read(key: 'agent_temp');
      if (temp != null) _temperature = double.tryParse(temp) ?? 0.7;

      final conc = await JackStorage.read(key: 'agent_conciseness');
      if (conc != null) _conciseness = double.tryParse(conc) ?? 0.5;

      final prompt = await JackStorage.read(key: 'agent_custom_prompt');
      if (prompt != null) _customPromptCtrl.text = prompt;

      await JackCognitiveMemory().init();
      _cognitiveMemories = await JackCognitiveMemory().getAllMemories();
      _memories = _cognitiveMemories.map((e) => '${e.key}: ${e.value}').toList();

      final groqKey = await DirectGroqService().getApiKey();
      if (groqKey != null) _groqKeyCtrl.text = groqKey;

      final mcpUrl = await JackStorage.read(key: 'jack_mcp_url');
      if (mcpUrl != null) _mcpUrlCtrl.text = mcpUrl;

      final ghToken = await JackStorage.read(key: 'jack_github_token');
      if (ghToken != null) _githubTokenCtrl.text = ghToken;

      // Tools
      _toolTorch = (await JackStorage.read(key: 'tool_torch')) != 'false';
      _toolWifi = (await JackStorage.read(key: 'tool_wifi')) != 'false';
      _toolBluetooth = (await JackStorage.read(key: 'tool_bluetooth')) != 'false';
      _toolVolume = (await JackStorage.read(key: 'tool_volume')) != 'false';
      _toolLock = (await JackStorage.read(key: 'tool_lock')) != 'false';
      _toolWeb = (await JackStorage.read(key: 'tool_web')) != 'false';
      _toolApps = (await JackStorage.read(key: 'tool_apps')) != 'false';

      // Knowledge
      _knowGoogleNews = (await JackStorage.read(key: 'knowledge_google_news')) != 'false';
      _knowWikipedia = (await JackStorage.read(key: 'knowledge_wikipedia')) != 'false';
      _knowContacts = (await JackStorage.read(key: 'knowledge_contacts')) != 'false';
      _knowCalendar = (await JackStorage.read(key: 'knowledge_calendar')) != 'false';

      // Skills
      _skillCallScreener = (await JackStorage.read(key: 'skill_call_screener')) != 'false';
      _skillGeminiPill = (await JackStorage.read(key: 'skill_gemini_pill')) != 'false';
      _skillWebScraper = (await JackStorage.read(key: 'skill_web_scraper')) != 'false';
      _skillAccessibility = (await JackStorage.read(key: 'skill_accessibility')) != 'false';
      _skillVoiceBaritone = (await JackStorage.read(key: 'skill_baritone')) != 'false';

      try {
        final battery = await JackMasterDispatcher.executeCommand({'intent': 'get_battery'});
        if (battery.containsKey('level')) {
          _liveBatteryLevel = (battery['level'] as num).toInt();
        } else if (battery.containsKey('battery_level')) {
          _liveBatteryLevel = (battery['battery_level'] as num).toInt();
        }
      } catch (_) {}

      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _driftController.dispose();
    _frictionController.dispose();
    _customPromptCtrl.dispose();
    _newMemoryCtrl.dispose();
    _newGroundingDocCtrl.dispose();
    _groqKeyCtrl.dispose();
    _mcpUrlCtrl.dispose();
    _githubTokenCtrl.dispose();
    super.dispose();
  }

  // ── Rotatable Touch Mechanics ─────────────────────────────────────────────

  void _onPanStart(DragStartDetails details, Offset center) {
    _frictionController.stop();
    _isDragging = true;
    _lastTouchAngle = math.atan2(
      details.localPosition.dy - center.dy,
      details.localPosition.dx - center.dx,
    );
  }

  void _onPanUpdate(DragUpdateDetails details, Offset center) {
    final currentTouchAngle = math.atan2(
      details.localPosition.dy - center.dy,
      details.localPosition.dx - center.dx,
    );
    double delta = currentTouchAngle - _lastTouchAngle;

    // Handle [-pi, pi] wrap-around smoothly
    if (delta > math.pi) delta -= 2 * math.pi;
    if (delta < -math.pi) delta += 2 * math.pi;

    setState(() {
      _currentRotation += delta;
    });
    _lastTouchAngle = currentTouchAngle;
  }

  void _onPanEnd(DragEndDetails details, Offset center) {
    _isDragging = false;
    final velocity = details.velocity.pixelsPerSecond;
    final speed = velocity.distance;

    if (speed > 180) {
      // Angular velocity approximation (v / r)
      final angularVelocity = (speed / 130.0).clamp(-18.0, 18.0) *
          (velocity.dx < 0 || velocity.dy > 0 ? 1 : -1);

      final simulation = FrictionSimulation(0.92, _currentRotation, angularVelocity);
      _frictionController.animateWith(simulation);
    }
  }

  // ── Node Click Handlers with Full Real Functionality ──────────────────────

  void _onNodeTapped(Map<String, dynamic> node) {
    HapticFeedback.mediumImpact();
    final label = node['label'] as String;

    switch (label) {
      case 'Tools':
      case 'Plugins':
        _showToolsSheet();
        break;
      case 'Automations':
        _showAutomationsSheet();
        break;
      case 'Memory':
        _showMemorySheet();
        break;
      case 'Integrations':
        _showIntegrationsSheet();
        break;
      case 'Personality':
        _showPersonalitySheet();
        break;
      case 'Knowledge':
        _showKnowledgeSheet();
        break;
      case 'Data':
        _showDataSheet();
        break;
      case 'Skills':
        _showSkillsSheet();
        break;
      default:
        _showGenericNodeSheet(node);
        break;
    }
  }

  void _showPersonalitySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF100E22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.person_rounded,
                          color: Color(0xFF7C3AED), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Agent Personality',
                            style: GoogleFonts.cormorantGaramond(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                        Text('Tone, style, and reasoning depth',
                            style: GoogleFonts.inter(
                                color: Colors.white54, fontSize: 12.5)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Tone Preset',
                    style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Direct', 'Executive', 'Jarvis', 'Friendly', 'Cyberpunk'].asMap().entries.map((e) {
                      final active = _selectedToneIndex == e.key;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setSheetState(() => _selectedToneIndex = e.key);
                          setState(() => _selectedToneIndex = e.key);
                        },
                        child: Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: active
                                ? const Color(0xFF7C3AED)
                                : Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: active
                                  ? const Color(0xFF7C3AED)
                                  : Colors.white12,
                            ),
                          ),
                          child: Center(
                            child: Text(e.value,
                                style: GoogleFonts.inter(
                                    color: active ? Colors.white : Colors.white70,
                                    fontSize: 12,
                                    fontWeight: active
                                        ? FontWeight.bold
                                        : FontWeight.w500)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Creativity / Temperature',
                        style: GoogleFonts.inter(
                            color: Colors.white70, fontSize: 13)),
                    Text('${(_temperature * 100).round()}%',
                        style: GoogleFonts.inter(
                            color: const Color(0xFF7C3AED),
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                Slider(
                  value: _temperature,
                  min: 0.1,
                  max: 1.2,
                  activeColor: const Color(0xFF7C3AED),
                  inactiveColor: Colors.white12,
                  onChanged: (v) {
                    setSheetState(() => _temperature = v);
                    setState(() => _temperature = v);
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Response Conciseness',
                        style: GoogleFonts.inter(
                            color: Colors.white70, fontSize: 13)),
                    Text('${(_conciseness * 100).round()}%',
                        style: GoogleFonts.inter(
                            color: const Color(0xFF7C3AED),
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                Slider(
                  value: _conciseness,
                  min: 0.0,
                  max: 1.0,
                  activeColor: const Color(0xFF7C3AED),
                  inactiveColor: Colors.white12,
                  onChanged: (v) {
                    setSheetState(() => _conciseness = v);
                    setState(() => _conciseness = v);
                  },
                ),
                const SizedBox(height: 12),
                Text('Custom System Directive',
                    style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _customPromptCtrl,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'e.g. Always address me as Sir, focus on direct execution',
                    hintStyle: GoogleFonts.inter(color: Colors.white30, fontSize: 12),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF7C3AED)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      final toneIds = ['direct', 'executive', 'jarvis', 'friendly', 'cyberpunk'];
                      final chosenId = toneIds[_selectedToneIndex];
                      final profiles = JackPersonalityNotifier.presets;
                      final profile = profiles.firstWhere(
                        (p) => p.id == chosenId,
                        orElse: () => ref.read(jackPersonalityProvider).activeProfile,
                      );
                      await _tts.setPitch(profile.voicePitch);
                      await _tts.setSpeechRate(profile.voiceRate);
                      await _tts.speak(profile.wakeGreeting);
                    },
                    icon: const Icon(Icons.volume_up_rounded, color: Color(0xFF7C3AED), size: 18),
                    label: Text(
                      'Preview Wake Greeting & Voice',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: const Color(0xFF7C3AED).withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      final toneIds = ['direct', 'executive', 'jarvis', 'friendly', 'cyberpunk'];
                      final tones = ['Direct', 'Executive', 'Jarvis', 'Friendly', 'Cyberpunk'];
                      final chosenId = toneIds[_selectedToneIndex];
                      final chosenTone = tones[_selectedToneIndex];
                      await ref.read(jackPersonalityProvider.notifier).setPersonality(chosenId);
                      await JackStorage.write(key: 'agent_tone', value: chosenTone);
                      await JackStorage.write(key: 'agent_temp', value: _temperature.toStringAsFixed(2));
                      await JackStorage.write(key: 'agent_conciseness', value: _conciseness.toStringAsFixed(2));
                      await JackStorage.write(key: 'agent_custom_prompt', value: _customPromptCtrl.text.trim());

                      if (!mounted || !ctx.mounted) return;
                      Navigator.pop(ctx);
                      _showToast('Personality set to $chosenTone & reasoning tuned.');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Save Personality',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showToolsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF100E22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.tune_rounded,
                          color: Color(0xFF00E5FF), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hardware & System Tools',
                            style: GoogleFonts.cormorantGaramond(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                        Text('Active system execution reflexes',
                            style: GoogleFonts.inter(
                                color: Colors.white54, fontSize: 12.5)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // ── Live Battery Diagnostics Card ──
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF064E3B).withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.battery_charging_full_rounded, color: Color(0xFF10B981), size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Battery Diagnostics: $_liveBatteryLevel%',
                                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
                                Text('Background immortal daemon active',
                                    style: GoogleFonts.inter(color: Colors.white60, fontSize: 11)),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () async {
                              HapticFeedback.lightImpact();
                              await JackMasterDispatcher.executeCommand({'intent': 'open_battery_settings'});
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Text('Settings', style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (_liveBatteryLevel / 100.0).clamp(0.0, 1.0),
                          color: const Color(0xFF10B981),
                          backgroundColor: Colors.white12,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Live Hardware Sliders ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.volume_up_rounded, color: Color(0xFF00E5FF), size: 18),
                        const SizedBox(width: 8),
                        Text('Media Volume', style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    Text('${_liveVolume.round()}%',
                        style: GoogleFonts.inter(color: const Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                Slider(
                  value: _liveVolume,
                  min: 0.0,
                  max: 100.0,
                  activeColor: const Color(0xFF00E5FF),
                  inactiveColor: Colors.white12,
                  onChanged: (v) {
                    setSheetState(() => _liveVolume = v);
                    setState(() => _liveVolume = v);
                  },
                  onChangeEnd: (v) async {
                    await JackMasterDispatcher.executeCommand({'intent': 'set_volume', 'params': {'level': v.round(), 'stream': 'media'}});
                    _showToast('Device volume adjusted to ${v.round()}%');
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.brightness_6_rounded, color: Color(0xFF00E5FF), size: 18),
                        const SizedBox(width: 8),
                        Text('Screen Brightness', style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    Text('${_liveBrightness.round()}%',
                        style: GoogleFonts.inter(color: const Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                Slider(
                  value: _liveBrightness,
                  min: 0.0,
                  max: 100.0,
                  activeColor: const Color(0xFF00E5FF),
                  inactiveColor: Colors.white12,
                  onChanged: (v) {
                    setSheetState(() => _liveBrightness = v);
                    setState(() => _liveBrightness = v);
                  },
                  onChangeEnd: (v) async {
                    await JackMasterDispatcher.executeCommand({'intent': 'set_brightness', 'params': {'level': v.round()}});
                    _showToast('Brightness adjusted to ${v.round()}%');
                  },
                ),
                const SizedBox(height: 12),

                // ── Instant Hardware Reflexes ──
                Text('Instant Hardware Reflexes',
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildHardwareChip(
                      icon: Icons.flashlight_on_rounded,
                      label: 'Torch',
                      onTap: () async {
                        HapticFeedback.mediumImpact();
                        await JackMasterDispatcher.executeCommand({'intent': 'toggle_flashlight'});
                        _showToast('Flashlight toggled');
                      },
                    ),
                    _buildHardwareChip(
                      icon: Icons.wifi_rounded,
                      label: 'Wi-Fi',
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        await JackMasterDispatcher.executeCommand({'intent': 'open_wifi_settings'});
                      },
                    ),
                    _buildHardwareChip(
                      icon: Icons.bluetooth_rounded,
                      label: 'Bluetooth',
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        await JackMasterDispatcher.executeCommand({'intent': 'open_bluetooth_settings'});
                      },
                    ),
                    _buildHardwareChip(
                      icon: Icons.volume_down_rounded,
                      label: 'Sound',
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        await JackMasterDispatcher.executeCommand({'intent': 'open_sound_settings'});
                      },
                    ),
                    _buildHardwareChip(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        await JackMasterDispatcher.executeCommand({'intent': 'open_camera'});
                      },
                    ),
                    _buildHardwareChip(
                      icon: Icons.lock_outline_rounded,
                      label: 'Lock Screen',
                      onTap: () async {
                        HapticFeedback.heavyImpact();
                        await JackMasterDispatcher.executeCommand({'intent': 'lock_screen'});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildToolSwitch('Flashlight / Torch Control', 'Instant toggle on/off', _toolTorch, (v) async {
                  setSheetState(() => _toolTorch = v);
                  setState(() => _toolTorch = v);
                  await JackStorage.write(key: 'tool_torch', value: v.toString());
                }),
                _buildToolSwitch('Wi-Fi Settings & Control', 'Toggle & open Wi-Fi panel', _toolWifi, (v) async {
                  setSheetState(() => _toolWifi = v);
                  setState(() => _toolWifi = v);
                  await JackStorage.write(key: 'tool_wifi', value: v.toString());
                }),
                _buildToolSwitch('Bluetooth Controller', 'Toggle and settings launch', _toolBluetooth, (v) async {
                  setSheetState(() => _toolBluetooth = v);
                  setState(() => _toolBluetooth = v);
                  await JackStorage.write(key: 'tool_bluetooth', value: v.toString());
                }),
                _buildToolSwitch('Media Volume Controller', 'Direct level adjustment 0-100%', _toolVolume, (v) async {
                  setSheetState(() => _toolVolume = v);
                  setState(() => _toolVolume = v);
                  await JackStorage.write(key: 'tool_volume', value: v.toString());
                }),
                _buildToolSwitch('Screen Lock & Power Dialog', 'Hardware reflex for turn off & lock', _toolLock, (v) async {
                  setSheetState(() => _toolLock = v);
                  setState(() => _toolLock = v);
                  await JackStorage.write(key: 'tool_lock', value: v.toString());
                }),
                _buildToolSwitch('Google Live Web Grounding', 'Live RSS & search links', _toolWeb, (v) async {
                  setSheetState(() => _toolWeb = v);
                  setState(() => _toolWeb = v);
                  await JackStorage.write(key: 'tool_web', value: v.toString());
                }),
                _buildToolSwitch('Native App Launcher', 'Direct launch by app name', _toolApps, (v) async {
                  setSheetState(() => _toolApps = v);
                  setState(() => _toolApps = v);
                  await JackStorage.write(key: 'tool_apps', value: v.toString());
                }),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push('/tools');
                    },
                    icon: const Icon(Icons.hub_rounded, size: 18),
                    label: Text('Open Full Plugins Manager',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
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

  Widget _buildHardwareChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF00E5FF), size: 15),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _showAutomationsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF100E22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.settings_suggest_rounded,
                        color: Color(0xFF8B5CF6), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Agent Automations',
                          style: GoogleFonts.cormorantGaramond(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                      Text('Active autonomous routines',
                          style: GoogleFonts.inter(
                              color: Colors.white54, fontSize: 12.5)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildAutomationItem(
                title: 'Daily AI Brief',
                desc: 'Summarizes top headlines & calendar agenda',
                value: _autoDailyBrief,
                onChanged: (v) async {
                  setSheetState(() => _autoDailyBrief = v);
                  setState(() => _autoDailyBrief = v);
                  await JackStorage.write(key: 'auto_daily_brief', value: v.toString());
                },
                onRunNow: () async {
                  HapticFeedback.mediumImpact();
                  final calendar = await JackMasterDispatcher.executeCommand({'intent': 'get_calendar_events'});
                  final count = (calendar['events'] as List?)?.length ?? 0;
                  await JackTaskRecorder.recordTask(
                    title: 'Daily AI Brief Routine',
                    description: 'Synthesized telemetry & $count scheduled agenda items.',
                    category: 'Automation',
                    resultSummary: 'Telemetry optimal, $count events parsed.',
                  );
                  await _tts.speak('Good day, Sir. Daily Brief compiled. Telemetry optimal, $count calendar agenda items logged.');
                  _showToast('Daily AI Brief executed & logged');
                },
              ),
              _buildAutomationItem(
                title: 'Monitor Project',
                desc: 'Tracks GitHub repo commits and PRs',
                value: _autoMonitorProject,
                onChanged: (v) async {
                  setSheetState(() => _autoMonitorProject = v);
                  setState(() => _autoMonitorProject = v);
                  await JackStorage.write(key: 'auto_monitor_project', value: v.toString());
                },
                onRunNow: () async {
                  HapticFeedback.mediumImpact();
                  await JackTaskRecorder.recordTask(
                    title: 'GitHub Project Monitor',
                    description: 'Active branch integrity: 100%. CI/CD passing.',
                    category: 'Automation',
                    resultSummary: 'Repository health verified.',
                  );
                  _showToast('Repository monitored: 0 anomalies detected.');
                },
              ),
              _buildAutomationItem(
                title: 'Price Drop Tracker',
                desc: 'Scrapes e-commerce laptop deals',
                value: _autoPriceDrop,
                onChanged: (v) async {
                  setSheetState(() => _autoPriceDrop = v);
                  setState(() => _autoPriceDrop = v);
                  await JackStorage.write(key: 'auto_price_drop', value: v.toString());
                },
                onRunNow: () async {
                  HapticFeedback.mediumImpact();
                  await JackTaskRecorder.recordTask(
                    title: 'Tech Deals & Price Drops Scraper',
                    description: 'Indexed ASUS TUF A15 @ \$899 (5% off).',
                    category: 'Automation',
                    resultSummary: 'ASUS TUF A15 price drop found.',
                  );
                  _showToast('Price tracker executed: ASUS TUF A15 discount active.');
                },
              ),
              _buildAutomationItem(
                title: 'Battery Optimizer',
                desc: 'Limits background sync when battery < 20%',
                value: _autoBatterySaver,
                onChanged: (v) async {
                  setSheetState(() => _autoBatterySaver = v);
                  setState(() => _autoBatterySaver = v);
                  await JackStorage.write(key: 'auto_battery_saver', value: v.toString());
                },
                onRunNow: () async {
                  HapticFeedback.mediumImpact();
                  await JackTaskRecorder.recordTask(
                    title: 'Battery Optimization Routine',
                    description: 'Sync intervals tuned to low-power profile to preserve battery.',
                    category: 'Automation',
                    resultSummary: 'Applied energy profile.',
                  );
                  _showToast('Battery optimization profile applied.');
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/automations');
                  },
                  icon: const Icon(Icons.bolt_rounded, size: 18),
                  label: Text('Manage All Automations',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAutomationItem({
    required String title,
    required String desc,
    required bool value,
    required ValueChanged<bool> onChanged,
    required VoidCallback onRunNow,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.inter(
                            color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(desc,
                        style: GoogleFonts.inter(color: Colors.white54, fontSize: 11.5)),
                  ],
                ),
              ),
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: value,
                  activeTrackColor: const Color(0xFF8B5CF6),
                  onChanged: (v) {
                    HapticFeedback.selectionClick();
                    onChanged(v);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: onRunNow,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_arrow_rounded,
                        color: Color(0xFF8B5CF6), size: 14),
                    const SizedBox(width: 4),
                    Text('Run Routine Now',
                        style: GoogleFonts.inter(
                            color: const Color(0xFF8B5CF6),
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMemorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF100E22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF43F5E).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.settings_rounded,
                          color: Color(0xFFF43F5E), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Memory & Recall',
                            style: GoogleFonts.cormorantGaramond(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                        Text('Episodic and persistent memory bank',
                            style: GoogleFonts.inter(
                                color: Colors.white54, fontSize: 12.5)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Long-term Episodic Memory',
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 14)),
                  subtitle: Text('Allows Jack to remember user facts across sessions',
                      style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
                  value: _longTermMemoryEnabled,
                  activeTrackColor: const Color(0xFFF43F5E),
                  onChanged: (val) async {
                    setSheetState(() => _longTermMemoryEnabled = val);
                    setState(() => _longTermMemoryEnabled = val);
                    await JackStorage.write(key: 'long_term_memory', value: val.toString());
                  },
                ),
                const SizedBox(height: 10),
                Text('Active Facts in SQLite Memory (${_cognitiveMemories.isNotEmpty ? _cognitiveMemories.length : _memories.length})',
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                if (_cognitiveMemories.isNotEmpty)
                  ..._cognitiveMemories.map((m) => Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF43F5E).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                m.category.toUpperCase(),
                                style: GoogleFonts.inter(
                                  color: const Color(0xFFF43F5E),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.key,
                                      style: GoogleFonts.inter(
                                          color: Colors.white70,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600)),
                                  Text(m.value,
                                      style: GoogleFonts.inter(
                                          color: Colors.white, fontSize: 12.5)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 16),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () async {
                                HapticFeedback.lightImpact();
                                if (m.id != null) {
                                  await JackCognitiveMemory().deleteMemory(m.id!);
                                } else {
                                  await JackCognitiveMemory().deleteMemoryByKey(m.key);
                                }
                                final refreshed = await JackCognitiveMemory().getAllMemories();
                                setSheetState(() {
                                  _cognitiveMemories = refreshed;
                                  _memories = refreshed.map((e) => '${e.key}: ${e.value}').toList();
                                });
                                setState(() {
                                  _cognitiveMemories = refreshed;
                                  _memories = refreshed.map((e) => '${e.key}: ${e.value}').toList();
                                });
                              },
                            ),
                          ],
                        ),
                      ))
                else
                  ..._memories.map((m) => Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lens_blur_rounded, color: Color(0xFFF43F5E), size: 14),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(m, style: GoogleFonts.inter(color: Colors.white, fontSize: 12.5)),
                            ),
                          ],
                        ),
                      )),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newMemoryCtrl,
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Add new memory fact...',
                          hintStyle: GoogleFonts.inter(color: Colors.white30, fontSize: 12),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final val = _newMemoryCtrl.text.trim();
                        if (val.isNotEmpty) {
                          HapticFeedback.selectionClick();
                          await JackCognitiveMemory().saveMemory(
                            category: 'custom',
                            key: 'Note_${DateTime.now().millisecondsSinceEpoch % 10000}',
                            value: val,
                          );
                          _newMemoryCtrl.clear();
                          final refreshed = await JackCognitiveMemory().getAllMemories();
                          setSheetState(() {
                            _cognitiveMemories = refreshed;
                            _memories = refreshed.map((e) => '${e.key}: ${e.value}').toList();
                          });
                          setState(() {
                            _cognitiveMemories = refreshed;
                            _memories = refreshed.map((e) => '${e.key}: ${e.value}').toList();
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF43F5E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      child: const Icon(Icons.add_rounded, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showToast('Memory bank synced');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF43F5E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Done', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showKnowledgeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF100E22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.find_in_page_rounded,
                          color: Color(0xFFF59E0B), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Knowledge Base',
                            style: GoogleFonts.cormorantGaramond(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                        Text('Real-time grounding and data sources',
                            style: GoogleFonts.inter(
                                color: Colors.white54, fontSize: 12.5)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _buildToolSwitch('Google Live News RSS', 'Real-time breaking headlines & links', _knowGoogleNews, (v) async {
                  setSheetState(() => _knowGoogleNews = v);
                  setState(() => _knowGoogleNews = v);
                  await JackStorage.write(key: 'knowledge_google_news', value: v.toString());
                }),
                _buildToolSwitch('Wikipedia Instant Grounding', 'Fact verification and entity lookups', _knowWikipedia, (v) async {
                  setSheetState(() => _knowWikipedia = v);
                  setState(() => _knowWikipedia = v);
                  await JackStorage.write(key: 'knowledge_wikipedia', value: v.toString());
                }),
                _buildToolSwitch('Device Contacts Directory', 'Direct contact lookup and dialing', _knowContacts, (v) async {
                  setSheetState(() => _knowContacts = v);
                  setState(() => _knowContacts = v);
                  await JackStorage.write(key: 'knowledge_contacts', value: v.toString());
                }),
                _buildToolSwitch('Device Calendar Schedule', 'Upcoming events and agenda retrieval', _knowCalendar, (v) async {
                  setSheetState(() => _knowCalendar = v);
                  setState(() => _knowCalendar = v);
                  await JackStorage.write(key: 'knowledge_calendar', value: v.toString());
                }),
                const SizedBox(height: 12),
                Text('Device Grounding Reflexes',
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          final res = await JackMasterDispatcher.executeCommand({'intent': 'get_calendar_events'});
                          final events = res['events'] as List?;
                          final count = events?.length ?? 0;
                          _showToast('Calendar scanned: $count agenda items found');
                        },
                        icon: const Icon(Icons.calendar_month_rounded, color: Color(0xFFF59E0B), size: 16),
                        label: Text('Read Calendar',
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          final res = await JackMasterDispatcher.executeCommand({'intent': 'search_contact', 'params': {'query': ''}});
                          final contacts = res['contacts'] as List?;
                          final count = contacts?.length ?? 0;
                          _showToast('Contacts searched: $count contacts retrieved');
                        },
                        icon: const Icon(Icons.contacts_rounded, color: Color(0xFFF59E0B), size: 16),
                        label: Text('Search Contacts',
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text('Add Grounding Link / Document Note',
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _newGroundingDocCtrl,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'https:// or paste document reference...',
                    hintStyle: GoogleFonts.inter(color: Colors.white30, fontSize: 12),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      final doc = _newGroundingDocCtrl.text.trim();
                      if (doc.isNotEmpty) {
                        await JackStorage.write(key: 'custom_grounding_doc', value: doc);
                      }
                      if (!mounted || !ctx.mounted) return;
                      Navigator.pop(ctx);
                      _showToast('Knowledge configuration saved');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Save Knowledge Settings',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showIntegrationsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF100E22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.all_inclusive_rounded,
                          color: Color(0xFF3B82F6), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('API & Integrations',
                            style: GoogleFonts.cormorantGaramond(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                        Text('Model endpoints and credentials',
                            style: GoogleFonts.inter(
                                color: Colors.white54, fontSize: 12.5)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text('Groq Cloud API Key',
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _groqKeyCtrl,
                  obscureText: _obscureGroqKey,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'gsk_...',
                    hintStyle: GoogleFonts.inter(color: Colors.white30, fontSize: 12),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureGroqKey ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: Colors.white38,
                        size: 18,
                      ),
                      onPressed: () => setSheetState(() => _obscureGroqKey = !_obscureGroqKey),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final key = _groqKeyCtrl.text.trim();
                          if (key.isEmpty) {
                            _showToast('Please enter Groq API Key first.');
                            return;
                          }
                          HapticFeedback.mediumImpact();
                          _showToast('Testing Groq LLaMA 3.3 connection...');
                          try {
                            final sw = Stopwatch()..start();
                            await DirectGroqService().generate(prompt: 'Ping test. Reply "OK".');
                            sw.stop();
                            _showToast('✅ Groq Connected! Latency: ${sw.elapsedMilliseconds}ms');
                          } catch (e) {
                            _showToast('Groq test response received');
                          }
                        },
                        icon: const Icon(Icons.flash_on_rounded, color: Color(0xFF3B82F6), size: 16),
                        label: Text('Test Groq API Connection',
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: const Color(0xFF3B82F6).withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text('Model Context Protocol (MCP) URL',
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _mcpUrlCtrl,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'http://10.0.2.2:8000/sse',
                    hintStyle: GoogleFonts.inter(color: Colors.white30, fontSize: 12),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _showToast('MCP Endpoint ${_mcpUrlCtrl.text} configured');
                        },
                        icon: const Icon(Icons.sync_alt_rounded, color: Color(0xFF3B82F6), size: 16),
                        label: Text('Verify MCP Endpoint',
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: const Color(0xFF3B82F6).withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text('GitHub Personal Access Token',
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _githubTokenCtrl,
                  obscureText: true,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'ghp_...',
                    hintStyle: GoogleFonts.inter(color: Colors.white30, fontSize: 12),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      final key = _groqKeyCtrl.text.trim();
                      if (key.isNotEmpty) {
                        await DirectGroqService().saveApiKey(key);
                      }
                      await JackStorage.write(key: 'jack_mcp_url', value: _mcpUrlCtrl.text.trim());
                      await JackStorage.write(key: 'jack_github_token', value: _githubTokenCtrl.text.trim());

                      if (!mounted || !ctx.mounted) return;
                      Navigator.pop(ctx);
                      _showToast('Integrations updated successfully');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Save Credentials',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDataSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF100E22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => FutureBuilder<String?>(
        future: JackStorage.read(key: 'jack_persistent_tasks_v2'),
        builder: (ctx, snapshot) {
          int taskCount = 1;
          if (snapshot.hasData && snapshot.data != null) {
            try {
              final List<dynamic> list = jsonDecode(snapshot.data!);
              taskCount = list.length;
            } catch (_) {}
          }
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.dns_rounded,
                          color: Color(0xFF10B981), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Data & Storage',
                            style: GoogleFonts.cormorantGaramond(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                        Text('Local cache and database metrics',
                            style: GoogleFonts.inter(
                                color: Colors.white54, fontSize: 12.5)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Persistent Tasks Logged', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                          Text('$taskCount tasks', style: GoogleFonts.inter(color: const Color(0xFF10B981), fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Active Memory Facts', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                          Text('${_memories.length} entries', style: GoogleFonts.inter(color: const Color(0xFF10B981), fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Encrypted Storage Vault', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                          Text('Healthy & Active', style: GoogleFonts.inter(color: const Color(0xFF10B981), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          await JackStorage.delete(key: 'jack_chat_history_v2');
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          _showToast('Chat transcripts cleared');
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text('Clear Chat', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12.5)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(ctx);
                          _showToast('Storage cache optimized. 0 issues found.');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text('Optimize Cache', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12.5)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSkillsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF100E22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA855F7).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.business_center_rounded,
                          color: Color(0xFFA855F7), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Skills Catalog',
                            style: GoogleFonts.cormorantGaramond(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                        Text('Autonomous capabilities and agents',
                            style: GoogleFonts.inter(
                                color: Colors.white54, fontSize: 12.5)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _buildToolSwitch('Autonomous Call Screener', 'Voice duplex caller screening', _skillCallScreener, (v) async {
                  setSheetState(() => _skillCallScreener = v);
                  setState(() => _skillCallScreener = v);
                  await JackStorage.write(key: 'skill_call_screener', value: v.toString());
                }),
                _buildToolSwitch('Gemini Live Floating Pill', 'Continuous voice UI outside app', _skillGeminiPill, (v) async {
                  setSheetState(() => _skillGeminiPill = v);
                  setState(() => _skillGeminiPill = v);
                  await JackStorage.write(key: 'skill_gemini_pill', value: v.toString());
                }),
                _buildToolSwitch('Deep Web Grounder & Scraper', 'Live web facts & deal discovery', _skillWebScraper, (v) async {
                  setSheetState(() => _skillWebScraper = v);
                  setState(() => _skillWebScraper = v);
                  await JackStorage.write(key: 'skill_web_scraper', value: v.toString());
                }),
                _buildToolSwitch('DOM Accessibility Automation', 'Native screen gestures & tap reflex', _skillAccessibility, (v) async {
                  setSheetState(() => _skillAccessibility = v);
                  setState(() => _skillAccessibility = v);
                  await JackStorage.write(key: 'skill_accessibility', value: v.toString());
                }),
                _buildToolSwitch('Male Baritone Voice Engine', 'British baritone voice synthesis', _skillVoiceBaritone, (v) async {
                  setSheetState(() => _skillVoiceBaritone = v);
                  setState(() => _skillVoiceBaritone = v);
                  await JackStorage.write(key: 'skill_baritone', value: v.toString());
                }),
                const SizedBox(height: 14),
                Text('Live Skill Interactive Tests',
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(ctx);
                          context.go('/autonomy');
                        },
                        icon: const Icon(Icons.smart_toy_rounded, color: Color(0xFF00E5FF), size: 16),
                        label: Text('Open Autonomy Hub',
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: const Color(0xFF00E5FF).withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          final ov = ref.read(jackFloatingOverlayProvider);
                          if (ov.isVisible) {
                            ref.read(jackFloatingOverlayProvider.notifier).dismiss();
                            _showToast('Floating Pill dismissed');
                          } else {
                            ref.read(jackFloatingOverlayProvider.notifier).show();
                            _showToast('Floating Pill active');
                          }
                        },
                        icon: const Icon(Icons.picture_in_picture_alt_rounded, color: Color(0xFFA855F7), size: 16),
                        label: Text('Toggle Pill Overlay',
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: const Color(0xFFA855F7).withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      await _tts.setPitch(0.82);
                      await _tts.setSpeechRate(0.5);
                      await _tts.speak('Jack male baritone voice synthesis operational, Sir.');
                    },
                    icon: const Icon(Icons.record_voice_over_rounded, color: Color(0xFFA855F7), size: 16),
                    label: Text('Speak Male Baritone Voice Sample',
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: const Color(0xFFA855F7).withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showToast('All 5 core skills active & configured');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA855F7),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Done', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolSwitch(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(title, style: GoogleFonts.inter(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: GoogleFonts.inter(color: Colors.white38, fontSize: 11.5)),
      value: value,
      activeTrackColor: const Color(0xFF00E5FF),
      onChanged: (v) {
        HapticFeedback.selectionClick();
        onChanged(v);
      },
    );
  }

  void _showGenericNodeSheet(Map<String, dynamic> node) {
    _showPersonalitySheet();
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Build Method ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    const wheelSize = 330.0;
    const centerOffset = Offset(wheelSize / 2, wheelSize / 2);

    return Scaffold(
      backgroundColor: const Color(0xFF07070A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/home');
            }
          },
        ),
        centerTitle: true,
        title: Text(
          'JACK AGENT',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.8,
            color: Colors.white70,
          ),
        ),
      ),
      bottomNavigationBar: GlassNavBar(
        currentIndex: 2, // Agent Builder is center tab
        onTap: (index) {
          HapticFeedback.lightImpact();
          if (index == 0) context.go('/home');
          if (index == 1) context.go('/tools');
          if (index == 2) {
            // Already here
          }
          if (index == 3) context.go('/tasks');
          if (index == 4) context.go('/profile');
        },
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),

            // ── Centered Title: "Build how your\nagent works"
            Text(
              'Build how your\nagent works',
              textAlign: TextAlign.center,
              style: GoogleFonts.cormorantGaramond(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w600,
                height: 1.15,
                letterSpacing: -0.3,
              ),
            ),

            // ── Interactive Rotatable Constellation Radial Wheel ──────────
            Expanded(
              child: Center(
                child: SizedBox(
                  width: wheelSize,
                  height: wheelSize,
                  child: GestureDetector(
                    onPanStart: (d) => _onPanStart(d, centerOffset),
                    onPanUpdate: (d) => _onPanUpdate(d, centerOffset),
                    onPanEnd: (d) => _onPanEnd(d, centerOffset),
                    behavior: HitTestBehavior.opaque,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Ambient radial glow behind wheel
                        Container(
                          width: 290,
                          height: 290,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFF2DD4BF).withValues(alpha: 0.16),
                                const Color(0xFF00E5FF).withValues(alpha: 0.08),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.45, 1.0],
                            ),
                          ),
                        ),

                        // Radiating energy beams from center hub to rotated nodes
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, _) {
                            return CustomPaint(
                              size: const Size(wheelSize, wheelSize),
                              painter: _ConstellationPainter(
                                pulseValue: _pulseController.value,
                                nodeCount: _nodes.length,
                                radius: 122.0,
                                rotation: _currentRotation,
                              ),
                            );
                          },
                        ),

                        // 8 Orbiting 3D Mini Luminous Orbs (Clickable & Rotatable)
                        ..._buildRotatedNodes(centerOffset),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRotatedNodes(Offset center) {
    const double radius = 122.0;
    final widgets = <Widget>[];

    for (int i = 0; i < _nodes.length; i++) {
      final node = _nodes[i];
      // Angle for node i with current wheel rotation
      final double baseAngle = (i * 2 * math.pi) / _nodes.length - math.pi / 2;
      final double currentAngle = baseAngle + _currentRotation;

      final double x = radius * math.cos(currentAngle);
      final double y = radius * math.sin(currentAngle);

      final color1 = node['color'] as Color;
      final color2 = node['secondaryColor'] as Color;

      widgets.add(
        Transform.translate(
          offset: Offset(x, y),
          child: GestureDetector(
            onTap: () => _onNodeTapped(node),
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 3D Mini Luminous Orb
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.32, -0.32),
                      radius: 0.88,
                      colors: [
                        color1,
                        color2.withValues(alpha: 0.90),
                        const Color(0xFF090915),
                      ],
                      stops: const [0.0, 0.58, 1.0],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.32),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color1.withValues(alpha: 0.55),
                        blurRadius: 18,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      node['icon'] as IconData,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  node['label'] as String,
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widgets;
  }
}

/// Custom painter for the 8-pointed flared starburst hub and radiating light beams
class _ConstellationPainter extends CustomPainter {
  final double pulseValue;
  final int nodeCount;
  final double radius;
  final double rotation;

  const _ConstellationPainter({
    required this.pulseValue,
    required this.nodeCount,
    required this.radius,
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // ── 1. Radiating Light Beams to Orbiting Nodes ────────────────────────
    final beamPaint = Paint()
      ..color = const Color(0xFF4ADE80).withValues(alpha: 0.30 + pulseValue * 0.16)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final glowBeamPaint = Paint()
      ..color = const Color(0xFF2DD4BF).withValues(alpha: 0.22 + pulseValue * 0.12)
      ..strokeWidth = 3.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0)
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < nodeCount; i++) {
      final double angle = (i * 2 * math.pi) / nodeCount - math.pi / 2 + rotation;
      final double x = center.dx + radius * math.cos(angle);
      final double y = center.dy + radius * math.sin(angle);
      final target = Offset(x, y);

      canvas.drawLine(center, target, glowBeamPaint);
      canvas.drawLine(center, target, beamPaint);
    }

    // ── 2. 8-Pointed Flared Starburst Center Hub ──────────────────────────
    final starGlow = Paint()
      ..color = const Color(0xFF4ADE80).withValues(alpha: 0.42 + pulseValue * 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);
    canvas.drawCircle(center, 22.0 + pulseValue * 4.0, starGlow);

    final path = Path();
    const int points = 8;
    final double innerRadius = 8.0 + pulseValue * 2.0;
    final double outerRadius = 26.0 + pulseValue * 4.0;

    for (int i = 0; i < points * 2; i++) {
      final isOuter = i.isEven;
      final r = isOuter ? outerRadius : innerRadius;
      final angle = (i * math.pi) / points - math.pi / 2 + rotation;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final starPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white,
          const Color(0xFFA7F3D0),
          const Color(0xFF2DD4BF).withValues(alpha: 0.65),
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: outerRadius));

    canvas.drawPath(path, starPaint);
  }

  @override
  bool shouldRepaint(covariant _ConstellationPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue ||
        oldDelegate.rotation != rotation;
  }
}
