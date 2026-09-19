// lib/screens/autonomy_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/glass_card.dart';
import '../widgets/jack_orb.dart';

class AutonomyScreen extends StatefulWidget {
  const AutonomyScreen({super.key});

  @override
  State<AutonomyScreen> createState() => _AutonomyScreenState();
}

class _AutonomyScreenState extends State<AutonomyScreen> with SingleTickerProviderStateMixin {
  int _tabIndex = 0;
  late AnimationController _arcCtrl;
  late Animation<double> _arcAnim;

  static const _tabs = ['Overview', 'Tools', 'Skills', 'Memory'];

  final _permissions = [
    _Permission('Browser', 'Allow', true, AppColors.accentCyan),
    _Permission('Email', 'Draft only', true, AppColors.accentBlue),
    _Permission('Files', 'Read', true, AppColors.accentViolet),
    _Permission('Social', 'Draft', true, AppColors.accentPink),
    _Permission('Payments', 'Never', false, AppColors.error),
  ];

  @override
  void initState() {
    super.initState();
    _arcCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _arcAnim = Tween<double>(begin: 0, end: 0.48).animate(
      CurvedAnimation(parent: _arcCtrl, curve: Curves.easeOut),
    );
    _arcCtrl.forward();
  }

  @override
  void dispose() {
    _arcCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Agent\nAutonomy', style: AppTypography.heading(size: 38)),
                    const SizedBox(height: 4),
                    Text('Build how your agent works.', style: AppTypography.body(size: 14)),
                    const SizedBox(height: 20),

                    // ── Tabs ──────────────────────────────────────────────────
                    Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.surfaceBorder),
                      ),
                      child: Row(
                        children: _tabs.asMap().entries.map((e) {
                          final isSelected = _tabIndex == e.key;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _tabIndex = e.key),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.accentCyan.withOpacity(0.15)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: Center(
                                  child: Text(e.value,
                                      style: AppTypography.caption(
                                          size: 12,
                                          color: isSelected
                                              ? AppColors.accentCyan
                                              : AppColors.textSecondary)),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            if (_tabIndex == 0) ...[
              // ── Overview tab ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Column(
                    children: [
                      // ── Circular score ────────────────────────────────────
                      _CircularScore(arcAnim: _arcAnim),
                      const SizedBox(height: 24),

                      // ── KPI row ───────────────────────────────────────────
                      Row(
                        children: [
                          Expanded(child: _KpiCard('12', 'Active\nAgents', AppColors.accentCyan)),
                          const SizedBox(width: 10),
                          Expanded(child: _KpiCard('28', 'Tasks\nCompleted', AppColors.accentViolet)),
                          const SizedBox(width: 10),
                          Expanded(child: _KpiCard('6.4h', 'Time\nSaved', AppColors.success)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Info card ─────────────────────────────────────────
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const JackOrb(size: 38, state: OrbState.idle),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Jack is learning and getting more capable every day.',
                                style: AppTypography.body(size: 13, color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Permissions ───────────────────────────────────────
                      GlassCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                              child: Text('Permissions',
                                  style: AppTypography.bodySemiBold(size: 14)),
                            ),
                            ..._permissions.asMap().entries.map((e) {
                              final isLast = e.key == _permissions.length - 1;
                              final p = e.value;
                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 30,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            color: p.color.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Center(
                                            child: Text(p.name[0],
                                                style: GoogleFonts.inter(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: p.color)),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(p.name,
                                              style: AppTypography.bodyMedium(size: 14)),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: p.color.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                                color: p.color.withOpacity(0.3)),
                                          ),
                                          child: Text(p.status,
                                              style: AppTypography.caption(
                                                  size: 11, color: p.color)),
                                        ),
                                        const SizedBox(width: 8),
                                        Switch(
                                          value: p.enabled,
                                          onChanged: (v) =>
                                              setState(() => p.enabled = v),
                                          activeColor: AppColors.accentCyan,
                                          inactiveTrackColor:
                                              AppColors.surfaceBorder,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!isLast)
                                    const Divider(
                                        height: 1,
                                        indent: 58,
                                        color: AppColors.surfaceBorder),
                                ],
                              );
                            }),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ] else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  child: GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          _tabIndex == 1
                              ? Icons.build_rounded
                              : _tabIndex == 2
                                  ? Icons.psychology_rounded
                                  : Icons.memory_rounded,
                          size: 48,
                          color: AppColors.accentCyan,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${_tabs[_tabIndex]} Configuration',
                          style: AppTypography.sectionHeading(size: 20),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Configure ${_tabs[_tabIndex].toLowerCase()} settings for Jack\'s autonomous behavior.',
                          style: AppTypography.body(size: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () => context.push('/agent-builder'),
                          child: Container(
                            width: double.infinity,
                            height: 46,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: const LinearGradient(
                                colors: [AppColors.accentCyan, AppColors.accentViolet],
                              ),
                            ),
                            child: Center(
                              child: Text('Open in Agent Builder',
                                  style: AppTypography.button(size: 14, color: Colors.white)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CircularScore extends StatelessWidget {
  final Animation<double> arcAnim;
  const _CircularScore({required this.arcAnim});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: arcAnim,
      builder: (context, _) {
        return SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(200, 200),
                painter: _ArcPainter(progress: arcAnim.value),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${(arcAnim.value * 100).round()}%',
                    style: AppTypography.kpi(size: 48),
                  ),
                  Text('Autonomy score', style: AppTypography.caption(size: 12)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '↑ 12% vs last week',
                      style: AppTypography.caption(size: 10, color: AppColors.success),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;
  const _ArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    // Background track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi * 0.75,
      pi * 1.5,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..color = AppColors.surfaceBorder,
    );

    // Gradient arc
    final arcRect = Rect.fromCircle(center: center, radius: radius);
    final sweepAngle = pi * 1.5 * progress;
    canvas.drawArc(
      arcRect,
      -pi * 0.75,
      sweepAngle,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: -pi * 0.75,
          endAngle: -pi * 0.75 + pi * 1.5,
          colors: const [AppColors.accentCyan, AppColors.accentViolet, AppColors.accentPink],
          tileMode: TileMode.clamp,
          transform: GradientRotation(-pi * 0.75),
        ).createShader(arcRect),
    );

    // Tip dot
    if (sweepAngle > 0) {
      final tipAngle = -pi * 0.75 + sweepAngle;
      final tipX = center.dx + radius * cos(tipAngle);
      final tipY = center.dy + radius * sin(tipAngle);
      canvas.drawCircle(
        Offset(tipX, tipY),
        6,
        Paint()..color = AppColors.accentCyan,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}

class _KpiCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _KpiCard(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      child: Column(
        children: [
          Text(value, style: AppTypography.kpi(size: 26, color: color)),
          const SizedBox(height: 4),
          Text(label,
              style: AppTypography.caption(size: 10),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _Permission {
  final String name;
  final String status;
  bool enabled;
  final Color color;
  _Permission(this.name, this.status, this.enabled, this.color);
}
