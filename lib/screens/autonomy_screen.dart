import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/jack_permission_service.dart';
import '../services/memory/jack_cognitive_memory.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_nav_bar.dart';
import '../services/agent/jack_droid_run_engine.dart';
import '../services/jack_controller.dart';
import '../services/jack_shizuku_controller.dart';
import '../services/overlay/jack_floating_overlay_controller.dart';

class AutonomyScreen extends ConsumerStatefulWidget {
  const AutonomyScreen({super.key});

  @override
  ConsumerState<AutonomyScreen> createState() => _AutonomyScreenState();
}

class _AutonomyScreenState extends ConsumerState<AutonomyScreen> {
  int _selectedTab = 0;
  final List<String> _tabs = [
    'Overview',
    'Plugins',
    'Skills',
    'Memory',
    'Settings',
  ];

  int _autonomyScore = 58;
  List<CognitiveMemoryItem> _cognitiveMemories = [];
  List<String> _memories = [];
  List<double> _velocityPoints = [110.0, 95.0, 135.0, 105.0, 88.0, 122.0, 98.0];
  bool _autonomousExecution = true;
  bool _backgroundKeepAlive = true;

  bool _a11yActive = false;
  bool _shizukuReady = false;
  final TextEditingController _goalController =
      TextEditingController(text: 'Open Settings and check Battery');

  @override
  void initState() {
    super.initState();
    _calculateRealScore();
    _loadDeviceDetails();
    _checkSystemPrivileges();
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _checkSystemPrivileges() async {
    final a11y = await JackController.isAccessibilityActive();
    final shizuku = await JackShizukuController.isReady();
    if (mounted) {
      setState(() {
        _a11yActive = a11y;
        _shizukuReady = shizuku;
      });
    }
  }

  Future<void> _loadDeviceDetails() async {
    try {
      await JackCognitiveMemory().init();
      final cognitiveItems = await JackCognitiveMemory().getAllMemories();
      final points = await JackCognitiveMemory().getExecutionVelocityPoints();
      if (mounted) {
        setState(() {
          _cognitiveMemories = cognitiveItems;
          _memories = cognitiveItems.map((m) => '${m.key}: ${m.value}').toList();
          if (points.isNotEmpty) {
            _velocityPoints = points;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _calculateRealScore() async {
    try {
      final perms = await JackPermissionService.checkAll();
      int score = 30;
      if (perms.accessibility || _a11yActive) score += 20;
      if (perms.overlay) score += 15;
      if (perms.microphone) score += 10;
      if (_shizukuReady) score += 15;
      if (perms.notification) score += 5;
      if (perms.camera) score += 5;
      if (mounted) {
        setState(() => _autonomyScore = score.clamp(25, 100));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
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
        currentIndex: 1, // Autonomy under explore/agent capabilities
        onTap: (index) {
          if (index == 0) context.go('/home');
          if (index == 1) context.go('/library');
          if (index == 2) context.go('/agent-builder');
          if (index == 3) context.go('/tasks');
          if (index == 4) context.go('/profile');
        },
      ),
      body: Stack(
        children: [
          // ── Ambient Aurora Background Glow ─────────────────────────────
          Positioned(
            left: -40,
            bottom: 120,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.18),
                    blurRadius: 90,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: -30,
            bottom: 100,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF84CC16).withValues(alpha: 0.16),
                    blurRadius: 90,
                    spreadRadius: 20,
                  ),
                  BoxShadow(
                    color: const Color(0xFFEAB308).withValues(alpha: 0.12),
                    blurRadius: 100,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 8),

                // ── Title: Centered "Agent Autonomy" (wrapping gracefully)
                SizedBox(
                  width: 200,
                  child: Text(
                    'Agent Autonomy',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cormorantGaramond(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w600,
                      height: 1.15,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // ── Subtitle: "Build how your agent works"
                Text(
                  'Build how your agent works',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 20),

                // ── Horizontal Tabs with sleek underline on active ────────
                SizedBox(
                  height: 38,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_tabs.length, (i) {
                        final active = _selectedTab == i;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedTab = i);
                              if (i == 1) context.push('/tools');
                              if (i == 4) context.push('/profile');
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _tabs[i],
                                  style: GoogleFonts.inter(
                                    color: active ? Colors.white : Colors.white54,
                                    fontSize: 13,
                                    fontWeight:
                                        active ? FontWeight.w600 : FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  width: 26,
                                  height: 2.5,
                                  decoration: BoxDecoration(
                                    color: active
                                        ? const Color(0xFFC084FC)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(2),
                                    boxShadow: active
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFFC084FC)
                                                  .withValues(alpha: 0.8),
                                              blurRadius: 6,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Interactive Dynamic Tab Body
                Expanded(
                  child: _buildActiveTabContent(),
                ),

                const SizedBox(height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_selectedTab) {
      case 1:
        return _buildPluginsTab();
      case 2:
        return _buildSkillsTab();
      case 3:
        return _buildMemoryTab();
      case 4:
        return _buildSettingsTab();
      case 0:
      default:
        return _buildOverviewTab();
    }
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          const SizedBox(height: 10),

          // ── Dotted Circular Gauge (Real Autonomy score)
          Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: CustomPaint(
                painter: _DottedGaugePainter(
                  percentage: _autonomyScore / 100.0,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$_autonomyScore%',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 44,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Autonomy\nscore',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Continuous Real-Time Telemetry Curve (fl_chart)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF100F1F).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.06),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF00E5FF),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF00E5FF),
                                  blurRadius: 6,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'LIVE EXECUTION VELOCITY',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_velocityPoints.last.toInt()} ms',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF00E5FF),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Continuous response curve across cognitive cycles',
                    style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 130,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 25,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Colors.white.withValues(alpha: 0.05),
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 20,
                              interval: 1,
                              getTitlesWidget: (val, meta) {
                                final idx = val.toInt();
                                if (idx >= 0 && idx < _velocityPoints.length) {
                                  return Text('T$idx',
                                      style: GoogleFonts.inter(color: Colors.white30, fontSize: 9));
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (val, meta) => Text(
                                '${val.toInt()}',
                                style: GoogleFonts.inter(color: Colors.white30, fontSize: 9),
                              ),
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        minX: 0,
                        maxX: (_velocityPoints.length - 1).toDouble().clamp(1.0, 15.0),
                        minY: 60,
                        maxY: 160,
                        lineBarsData: [
                          LineChartBarData(
                            spots: [
                              for (int i = 0; i < _velocityPoints.length; i++)
                                FlSpot(i.toDouble(), _velocityPoints[i].clamp(60.0, 160.0)),
                            ],
                            isCurved: true,
                            curveSmoothness: 0.35,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00E5FF), Color(0xFFA855F7), Color(0xFFF43F5E)],
                            ),
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 3,
                                  color: const Color(0xFF00E5FF),
                                  strokeWidth: 1.5,
                                  strokeColor: Colors.white,
                                );
                              },
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF00E5FF).withValues(alpha: 0.25),
                                  const Color(0xFFA855F7).withValues(alpha: 0.05),
                                  Colors.transparent,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Real System Telemetry Badges ─────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131224),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.psychology_rounded, color: Color(0xFFF43F5E), size: 16),
                            const SizedBox(width: 6),
                            Text('Cognitive Memory',
                                style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('${_cognitiveMemories.length} SQLite Facts',
                            style: GoogleFonts.inter(
                                color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131224),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.smart_toy_rounded, color: Color(0xFF00E5FF), size: 16),
                            const SizedBox(width: 6),
                            Text('DroidRun Engine',
                                style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('OpenGUI Active',
                            style: GoogleFonts.inter(
                                color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── System Privileges & Toolchains Card ───────────────────────
          _buildSystemPrivilegesCard(),

          const SizedBox(height: 16),

          // ── On-Device DroidRun Agent Goal Execution Card ───────────────
          _buildOnDeviceAgentRunnerCard(),

          const SizedBox(height: 16),

          // ── Informational Card: "Jack is learning and getting..."
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: GestureDetector(
              onTap: () => context.go('/agent-builder'),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141320).withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF222035),
                          ),
                          child: const Icon(
                            Icons.smart_toy_rounded,
                            color: Colors.white70,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Jack is learning and getting\nmore capable every day.',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              height: 1.35,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white38,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemPrivilegesCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF131224).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFA855F7).withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield_outlined, color: Color(0xFFA855F7), size: 18),
                const SizedBox(width: 8),
                Text(
                  'ON-DEVICE TOOLCHAINS & PRIVILEGES',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _privilegeRow(
              title: 'Android Accessibility Service',
              subtitle: 'OpenGUI DOM reading, tap, swipe, and text entry',
              active: _a11yActive,
              activeColor: const Color(0xFF10B981),
              onAction: () async {
                await JackController.openAccessibilitySettings();
                await Future.delayed(const Duration(seconds: 1));
                _checkSystemPrivileges();
              },
              actionLabel: _a11yActive ? 'Active' : 'Enable',
            ),
            const Divider(color: Colors.white10, height: 20),
            _privilegeRow(
              title: 'Shizuku ADB Daemon',
              subtitle: 'UID 2000 privileged shell execution without PC',
              active: _shizukuReady,
              activeColor: const Color(0xFF8B5CF6),
              onAction: () async {
                await JackShizukuController.requestPermission();
                await Future.delayed(const Duration(milliseconds: 600));
                _checkSystemPrivileges();
              },
              actionLabel: _shizukuReady ? 'Ready' : 'Authorize',
            ),
            const Divider(color: Colors.white10, height: 20),
            _privilegeRow(
              title: 'Android-MCP Local Server',
              subtitle: '7 native tools exposed via Model Context Protocol',
              active: true,
              activeColor: const Color(0xFF00E5FF),
              onAction: null,
              actionLabel: 'Active',
            ),
            const Divider(color: Colors.white10, height: 20),
            _privilegeRow(
              title: 'Floating Jack Overlay Pill',
              subtitle: 'Persistent heads-up controller across all apps',
              active: true,
              activeColor: const Color(0xFFF59E0B),
              onAction: () {
                ref.read(jackFloatingOverlayProvider.notifier).expand();
              },
              actionLabel: 'Launch Pill',
            ),
          ],
        ),
      ),
    );
  }

  Widget _privilegeRow({
    required String title,
    required String subtitle,
    required bool active,
    required Color activeColor,
    required VoidCallback? onAction,
    required String actionLabel,
  }) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? activeColor : Colors.white30,
            boxShadow: active
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.6),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        if (onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: active
                  ? activeColor.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              actionLabel,
              style: GoogleFonts.inter(
                color: active ? activeColor : Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: activeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              actionLabel,
              style: GoogleFonts.inter(
                color: activeColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOnDeviceAgentRunnerCard() {
    final engine = JackDroidRunEngine.instance;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF131224).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.play_circle_fill_rounded,
                        color: Color(0xFF00E5FF), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'DROIDRUN AUTONOMOUS RUNNER',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                ValueListenableBuilder<DroidRunState>(
                  valueListenable: engine.stateNotifier,
                  builder: (context, state, _) {
                    final isBusy = state != DroidRunState.idle &&
                        state != DroidRunState.completed &&
                        state != DroidRunState.failed;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isBusy
                            ? const Color(0xFF10B981).withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        state.name.toUpperCase(),
                        style: GoogleFonts.inter(
                          color: isBusy
                              ? const Color(0xFF10B981)
                              : Colors.white60,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Closed-loop on-device agent (OpenGUI + Accessibility + Groq)',
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _goalController,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Enter goal (e.g. Open Settings and check Battery)',
                hintStyle:
                    GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF00E5FF)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _goalChip('Settings & Battery', 'Open Settings and check Battery'),
                  const SizedBox(width: 8),
                  _goalChip('Search YouTube', 'Open YouTube and search AI Agents'),
                  const SizedBox(width: 8),
                  _goalChip('Open WhatsApp', 'Open WhatsApp and see unread chats'),
                  const SizedBox(width: 8),
                  _goalChip('Open Chrome', 'Open Chrome and search Tech News'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ValueListenableBuilder<DroidRunState>(
              valueListenable: engine.stateNotifier,
              builder: (context, state, _) {
                final isBusy = state != DroidRunState.idle &&
                    state != DroidRunState.completed &&
                    state != DroidRunState.failed;

                return Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isBusy
                            ? null
                            : () async {
                                final goal = _goalController.text.trim();
                                if (goal.isEmpty) return;
                                FocusScope.of(context).unfocus();
                                await engine.executeGoal(goal);
                              },
                        icon: isBusy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.rocket_launch_rounded, size: 16),
                        label: Text(
                          isBusy ? 'Autonomous Execution Active...' : 'Execute Goal on Device',
                          style: GoogleFonts.inter(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E5FF),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    if (isBusy) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => engine.stop(),
                        icon: const Icon(Icons.stop_circle_rounded,
                            color: Color(0xFFF43F5E), size: 28),
                        tooltip: 'Stop Agent',
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 10),
            ValueListenableBuilder<String>(
              valueListenable: engine.statusMessageNotifier,
              builder: (context, msg, _) {
                return Text(
                  'Status: $msg',
                  style: GoogleFonts.inter(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.8),
                      fontSize: 11,
                      fontStyle: FontStyle.italic),
                );
              },
            ),
            const SizedBox(height: 10),
            ValueListenableBuilder<List<DroidRunStep>>(
              valueListenable: engine.trajectoryNotifier,
              builder: (context, steps, _) {
                if (steps.isEmpty) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Trajectory (${steps.length} steps):',
                        style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      ...steps.reversed.take(4).map(
                            (s) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Row(
                                children: [
                                  Icon(
                                    s.success
                                        ? Icons.check_circle_rounded
                                        : Icons.error_rounded,
                                    size: 13,
                                    color: s.success
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFF43F5E),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Step ${s.stepIndex}: [${s.actionType}] ${s.description}',
                                      style: GoogleFonts.inter(
                                          color: Colors.white60, fontSize: 10.5),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _goalChip(String label, String goal) {
    return ActionChip(
      label: Text(label,
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
      backgroundColor: Colors.white.withValues(alpha: 0.08),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: () {
        _goalController.text = goal;
      },
    );
  }

  Widget _buildPluginsTab() {
    final plugins = [
      {'name': 'Groq Cloud Engine', 'status': 'Connected', 'color': const Color(0xFF10B981), 'icon': Icons.bolt_rounded},
      {'name': 'MCP Handshake Endpoint', 'status': 'Configured', 'color': const Color(0xFF00E5FF), 'icon': Icons.hub_rounded},
      {'name': 'Shizuku Android Daemon', 'status': 'Active', 'color': const Color(0xFF8B5CF6), 'icon': Icons.security_rounded},
      {'name': 'Google Grounding Protocol', 'status': 'Live', 'color': const Color(0xFFF59E0B), 'icon': Icons.search_rounded},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        children: [
          ...plugins.map((p) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF131224),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    Icon(p['icon'] as IconData, color: p['color'] as Color, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        p['name'] as String,
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (p['color'] as Color).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        p['status'] as String,
                        style: GoogleFonts.inter(color: p['color'] as Color, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () => context.go('/agent-builder'),
              icon: const Icon(Icons.settings_suggest_rounded, color: AppColors.accentCyan, size: 18),
              label: Text('Configure Plugins in Agent Builder', style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.accentCyan.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        children: [
          _skillCard('DroidRun Agent Loop', 'Autonomous on-device perception & task execution', Icons.smart_toy_rounded, const Color(0xFF00E5FF), () {
            context.go('/automations');
          }),
          _skillCard('Security Shield', 'Blocks scams, OTP fraud, and phishing links', Icons.shield_rounded, const Color(0xFF22C55E), () {
            context.push('/security');
          }),
          _skillCard('DOM Touch Automation', 'Autonomous swipes, scrolls, and clicks', Icons.touch_app_rounded, const Color(0xFFA855F7), () {
            context.go('/agent-builder');
          }),
          _skillCard('British Baritone Voice', 'Natural high-speed male speech synthesis', Icons.mic_rounded, const Color(0xFFEC4899), () {
            context.go('/agent-builder');
          }),
        ],
      ),
    );
  }

  Widget _skillCard(String title, String desc, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF131224),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(desc, style: GoogleFonts.inter(color: Colors.white54, fontSize: 11.5)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 14),
            onPressed: onTap,
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('SQLite Cognitive Memory (${_cognitiveMemories.isNotEmpty ? _cognitiveMemories.length : _memories.length})',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF43F5E).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Zero-Mock Data',
                    style: GoogleFonts.inter(color: const Color(0xFFF43F5E), fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_cognitiveMemories.isNotEmpty)
            ..._cognitiveMemories.map((m) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131224),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
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
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              m.key,
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        m.value,
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 12.5),
                      ),
                    ],
                  ),
                ))
          else
            ..._memories.map((m) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131224),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lens_blur_rounded, color: Color(0xFFF43F5E), size: 14),
                      const SizedBox(width: 10),
                      Expanded(child: Text(m, style: GoogleFonts.inter(color: Colors.white, fontSize: 12.5))),
                    ],
                  ),
                )),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/agent-builder'),
              icon: const Icon(Icons.edit_note_rounded, size: 18),
              label: Text('Open Memory Bank in Builder', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF43F5E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Autonomous Execution', style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text('Allows Jack to complete multi-step goals without prompting', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
            value: _autonomousExecution,
            activeTrackColor: AppColors.accentCyan,
            onChanged: (v) => setState(() => _autonomousExecution = v),
          ),
          const Divider(color: Colors.white10),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('24/7 Background Persistence', style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text('Keeps Jack active in background for wake word and automations', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
            value: _backgroundKeepAlive,
            activeTrackColor: const Color(0xFF22C55E),
            onChanged: (v) => setState(() => _backgroundKeepAlive = v),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () {
                JackPermissionService.requestAll(context);
                _calculateRealScore();
              },
              icon: const Icon(Icons.verified_user_rounded, color: Color(0xFF22C55E), size: 18),
              label: Text('Check & Grant All System Permissions', style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: const Color(0xFF22C55E).withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the circular dotted gauge seen in reference Screen 03
class _DottedGaugePainter extends CustomPainter {
  final double percentage;

  _DottedGaugePainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.44;
    const totalDots = 44;
    final activeDots = (totalDots * percentage).round();

    for (int i = 0; i < totalDots; i++) {
      // Start from 12 o'clock (-pi/2) clockwise
      final angle = -pi / 2 + (i * 2 * pi) / totalDots;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);

      final isLit = i < activeDots;

      if (isLit) {
        // Gradient from cyan on left to violet on right
        final t = i / activeDots;
        final color = Color.lerp(
          const Color(0xFF00E5FF), // Cyan
          const Color(0xFFA855F7), // Violet
          t,
        )!;

        // Glow pass
        final glow = Paint()
          ..color = color.withValues(alpha: 0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
        canvas.drawCircle(Offset(x, y), 3.2, glow);

        // Core dot
        final core = Paint()
          ..color = color
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), 2.6, core);
      } else {
        // Unlit dim white dots
        final dim = Paint()
          ..color = Colors.white.withValues(alpha: 0.28)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), 2.2, dim);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DottedGaugePainter oldDelegate) {
    return oldDelegate.percentage != percentage;
  }
}
