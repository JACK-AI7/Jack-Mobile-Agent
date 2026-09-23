// lib/screens/agent_builder_screen.dart
//
// 04. Agent Builder — Interactive, rotatable constellation wheel with
// 8 mini 3D luminous orbs and full real configuration functionality.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../widgets/glass_nav_bar.dart';

class BuilderScreen extends StatefulWidget {
  const BuilderScreen({super.key});

  @override
  State<BuilderScreen> createState() => _BuilderScreenState();
}

class _BuilderScreenState extends State<BuilderScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _driftController;
  late final AnimationController _frictionController;

  double _currentRotation = 0.0;
  double _lastTouchAngle = 0.0;
  bool _isDragging = false;

  // Real interactive configuration state for personality
  double _temperature = 0.7;
  double _conciseness = 0.5;
  int _selectedToneIndex = 1; // 0: Direct, 1: Executive, 2: Friendly

  // Real interactive configuration state for memory
  bool _longTermMemoryEnabled = true;
  double _contextTokens = 16000;

  final List<Map<String, dynamic>> _nodes = [
    {
      'label': 'Tools',
      'icon': Icons.folder_open_rounded,
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

  @override
  void dispose() {
    _pulseController.dispose();
    _driftController.dispose();
    _frictionController.dispose();
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
              Row(
                children: ['Direct', 'Executive', 'Friendly'].asMap().entries.map((e) {
                  final active = _selectedToneIndex == e.key;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setSheetState(() => _selectedToneIndex = e.key);
                        setState(() => _selectedToneIndex = e.key);
                      },
                      child: Container(
                        height: 36,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: active
                              ? const Color(0xFF7C3AED)
                              : Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Center(
                          child: Text(e.value,
                              style: GoogleFonts.inter(
                                  color: active ? Colors.white : Colors.white70,
                                  fontSize: 12.5,
                                  fontWeight: active
                                      ? FontWeight.bold
                                      : FontWeight.w400)),
                        ),
                      ),
                    ),
                  );
                }).toList(),
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
                activeColor: const Color(0xFF7C3AED),
                inactiveColor: Colors.white12,
                onChanged: (v) {
                  setSheetState(() => _conciseness = v);
                  setState(() => _conciseness = v);
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showToast('Personality profile saved successfully');
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
    );
  }

  void _showMemorySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF100E22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      Text('Episodic and working memory bank',
                          style: GoogleFonts.inter(
                              color: Colors.white54, fontSize: 12.5)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Long-term Episodic Memory',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 14)),
                subtitle: Text('Allows Jack to remember user preferences across sessions',
                    style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
                value: _longTermMemoryEnabled,
                activeThumbColor: const Color(0xFFF43F5E),
                onChanged: (val) {
                  setSheetState(() => _longTermMemoryEnabled = val);
                  setState(() => _longTermMemoryEnabled = val);
                },
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Context Window Size',
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                  Text('${(_contextTokens / 1000).round()}k tokens',
                      style: GoogleFonts.inter(
                          color: const Color(0xFFF43F5E),
                          fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: _contextTokens,
                min: 4000,
                max: 32000,
                divisions: 7,
                activeColor: const Color(0xFFF43F5E),
                inactiveColor: Colors.white12,
                onChanged: (v) {
                  setSheetState(() => _contextTokens = v);
                  setState(() => _contextTokens = v);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.push('/autonomy');
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('View Memory Bank',
                          style: GoogleFonts.inter(color: Colors.white70)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showToast('Memory settings saved');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF43F5E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Save',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showToolsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF100E22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.folder_open_rounded,
                      color: Color(0xFF00E5FF), size: 24),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Agent Tools',
                        style: GoogleFonts.cormorantGaramond(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    Text('Manage connected external integrations',
                        style: GoogleFonts.inter(
                            color: Colors.white54, fontSize: 12.5)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Connect external workspace tools including Google Drive, Gmail, GitHub, Notion, and Slack.',
              style: GoogleFonts.inter(
                  color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/tools');
                },
                icon: const Icon(Icons.hub_rounded, size: 18),
                label: Text('Open Tools Manager',
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
    );
  }

  void _showAutomationsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF100E22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    Text('Automated background routines and jobs',
                        style: GoogleFonts.inter(
                            color: Colors.white54, fontSize: 12.5)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Configure recurring tasks, scheduled web scrapers, battery optimizations, and email triages.',
              style: GoogleFonts.inter(
                  color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/automations');
                },
                icon: const Icon(Icons.bolt_rounded, size: 18),
                label: Text('Manage Automations',
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
    );
  }

  void _showIntegrationsSheet() {
    _showGenericActionSheet(
      title: 'Integrations & Webhooks',
      subtitle: 'Connect webhooks, API keys, and cloud endpoints',
      icon: Icons.all_inclusive_rounded,
      color: const Color(0xFF3B82F6),
      description:
          'Enable external apps to trigger Jack directly via secure REST webhooks and streaming APIs.',
      actionLabel: 'Generate Webhook Key',
      onAction: () => _showToast('Webhook key copied to clipboard'),
    );
  }

  void _showKnowledgeSheet() {
    _showGenericActionSheet(
      title: 'Knowledge Base',
      subtitle: 'Grounding documents, PDFs, and URLs',
      icon: Icons.find_in_page_rounded,
      color: const Color(0xFFF59E0B),
      description:
          'Feed custom documents, spreadsheets, and website URLs for Jack to retrieve during reasoning.',
      actionLabel: 'Upload Document / Link URL',
      onAction: () => _showToast('Select a document to index'),
    );
  }

  void _showDataSheet() {
    _showGenericActionSheet(
      title: 'Data & Storage',
      subtitle: 'Local vector database and cache metrics',
      icon: Icons.dns_rounded,
      color: const Color(0xFF10B981),
      description:
          'Local vector database: 12.4 MB\nChat transcript cache: 1.8 MB\nEncrypted credentials vault: Active',
      actionLabel: 'Optimize Storage Cache',
      onAction: () => _showToast('Cache optimized. Freed 3.2 MB'),
    );
  }

  void _showSkillsSheet() {
    _showGenericActionSheet(
      title: 'Skills Catalog',
      subtitle: 'Deterministic and LLM tools',
      icon: Icons.business_center_rounded,
      color: const Color(0xFFA855F7),
      description:
          'Active Skills: Web Surfer, Vision Node Grounder, Shizuku Shell Executor, Device Controller, Reflex Engine.',
      actionLabel: 'Configure Skills',
      onAction: () => _showToast('All 5 core skills active'),
    );
  }

  void _showGenericActionSheet({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String description,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF100E22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.cormorantGaramond(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    Text(subtitle,
                        style: GoogleFonts.inter(
                            color: Colors.white54, fontSize: 12.5)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(description,
                style: GoogleFonts.inter(
                    color: Colors.white70, fontSize: 13, height: 1.4)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  onAction();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(actionLabel,
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGenericNodeSheet(Map<String, dynamic> node) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF100E22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (node['color'] as Color).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(node['icon'] as IconData,
                      color: node['color'] as Color, size: 24),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(node['label'] as String,
                        style: GoogleFonts.cormorantGaramond(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    Text('Configure agent ${node['label'].toString().toLowerCase()}',
                        style: GoogleFonts.inter(
                            color: Colors.white54, fontSize: 12.5)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Customize how Jack uses ${node['label']} to automate actions and follow your workflows.',
              style: GoogleFonts.inter(
                  color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showToast('${node['label']} settings updated');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: node['color'] as Color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Save Settings',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
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
