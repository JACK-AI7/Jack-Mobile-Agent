// lib/widgets/animations/animated_beam.dart
//
// Flutter implementation of Magic UI's Animated Beam (https://magicui.design/docs/components/animated-beam)
// An animated beam of glowing neon light that travels along a curved bezier path,
// connecting cloud integration endpoints into our central Jack Agent Core.
// DYNAMIC: Renders ONLY currently connected plugins and active neural beams.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../jack_orb.dart';

/// Representation of a connected tool/plugin displayed on the Animated Beam Hub.
class BeamPluginItem {
  final String id;
  final String name;
  final String svgAsset;
  final Color primaryColor;
  final Color secondaryColor;

  const BeamPluginItem({
    required this.id,
    required this.name,
    required this.svgAsset,
    this.primaryColor = const Color(0xFF00E5FF),
    this.secondaryColor = const Color(0xFF7C3AED),
  });
}

/// Single Animated Beam Painter that renders a traveling pulse of light
/// along a cubic bezier curve between two relative coordinate points.
class AnimatedBeamPath {
  final Offset start;
  final Offset end;
  final double curvature;
  final double startYOffset;
  final double endYOffset;
  final bool reverse;
  final Color fromColor;
  final Color toColor;

  const AnimatedBeamPath({
    required this.start,
    required this.end,
    this.curvature = 0.0,
    this.startYOffset = 0.0,
    this.endYOffset = 0.0,
    this.reverse = false,
    this.fromColor = const Color(0xFF00E5FF), // Cyan
    this.toColor = const Color(0xFF7C3AED), // Violet
  });
}

class AnimatedBeamPainter extends CustomPainter {
  final List<AnimatedBeamPath> beams;
  final double progress;

  AnimatedBeamPainter({
    required this.beams,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final beam in beams) {
      _paintSingleBeam(canvas, size, beam);
    }
  }

  void _paintSingleBeam(Canvas canvas, Size size, AnimatedBeamPath beam) {
    final p0 = Offset(
      beam.start.dx,
      beam.start.dy + beam.startYOffset,
    );
    final p3 = Offset(
      beam.end.dx,
      beam.end.dy + beam.endYOffset,
    );

    // Calculate bezier control points based on curvature
    final midX = (p0.dx + p3.dx) / 2;
    final deltaY = (p3.dy - p0.dy);
    final curveOffset = beam.curvature;

    final p1 = Offset(midX, p0.dy + deltaY * 0.15 + curveOffset);
    final p2 = Offset(midX, p3.dy - deltaY * 0.15 + curveOffset);

    final path = Path()
      ..moveTo(p0.dx, p0.dy)
      ..cubicTo(p1.dx, p1.dy, p2.dx, p2.dy, p3.dx, p3.dy);

    // 1. Draw subtle background track path
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawPath(path, trackPaint);

    // 2. Sample path metric to extract the traveling animated beam slice
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final metric = metrics.first;
    final totalLength = metric.length;

    // Beam travels along path
    final double animVal = beam.reverse ? (1.0 - progress) : progress;
    const double beamLengthFraction = 0.32; // Length of the traveling light beam
    final double beamLength = totalLength * beamLengthFraction;

    final double headDistance = (animVal * (totalLength + beamLength)) - (beamLength / 2);
    final double tailDistance = headDistance - beamLength;

    final double validStart = tailDistance.clamp(0.0, totalLength);
    final double validEnd = headDistance.clamp(0.0, totalLength);

    if (validEnd > validStart) {
      final extractPath = metric.extractPath(validStart, validEnd);

      // Gradient shader along the beam segment
      final gradientPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round
        ..shader = ui.Gradient.linear(
          p0,
          p3,
          [
            beam.fromColor.withValues(alpha: 0.1),
            beam.fromColor,
            beam.toColor,
            Colors.white,
          ],
          const [0.0, 0.45, 0.85, 1.0],
        );

      // Outer glow pass
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.5
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5)
        ..color = beam.fromColor.withValues(alpha: 0.45);

      canvas.drawPath(extractPath, glowPaint);
      canvas.drawPath(extractPath, gradientPaint);

      // Glowing tip particle at beam head
      final tangent = metric.getTangentForOffset(validEnd);
      if (tangent != null && validEnd < totalLength && validEnd > 0) {
        final tipGlow = Paint()
          ..color = Colors.white
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
        canvas.drawCircle(tangent.position, 2.8, tipGlow);

        final tipCore = Paint()..color = Colors.white;
        canvas.drawCircle(tangent.position, 1.6, tipCore);
      }
    }
  }

  @override
  bool shouldRepaint(covariant AnimatedBeamPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// The complete integration hub component featuring:
/// - Left column of ONLY connected integration nodes
/// - Center: OUR LOGO (Authentic Jack Glowing Orb with capsule eyes)
/// - Right column of ONLY connected integration nodes
/// - Real animated beams pulsing ONLY for active, connected plugins
class JackAnimatedBeamHub extends StatefulWidget {
  final List<BeamPluginItem> connectedPlugins;
  final VoidCallback? onCenterTap;
  final ValueChanged<String>? onToolTap;

  const JackAnimatedBeamHub({
    super.key,
    required this.connectedPlugins,
    this.onCenterTap,
    this.onToolTap,
  });

  @override
  State<JackAnimatedBeamHub> createState() => _JackAnimatedBeamHubState();
}

class _JackAnimatedBeamHubState extends State<JackAnimatedBeamHub>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  final GlobalKey _containerKey = GlobalKey();
  final GlobalKey _centerKey = GlobalKey();
  final Map<String, GlobalKey> _nodeKeys = {};

  List<AnimatedBeamPath> _beamPaths = [];
  bool _pathsCalculated = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();

    _ensureKeys();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateBeamPaths();
    });
  }

  void _ensureKeys() {
    for (final item in widget.connectedPlugins) {
      if (!_nodeKeys.containsKey(item.id)) {
        _nodeKeys[item.id] = GlobalKey();
      }
    }
  }

  @override
  void didUpdateWidget(covariant JackAnimatedBeamHub oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ensureKeys();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateBeamPaths();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Offset _getCenterOffset(GlobalKey key, RenderBox containerBox) {
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return Offset.zero;
    final localPos = containerBox.globalToLocal(
      renderBox.localToGlobal(Offset.zero),
    );
    return Offset(
      localPos.dx + renderBox.size.width / 2,
      localPos.dy + renderBox.size.height / 2,
    );
  }

  void _calculateBeamPaths() {
    if (!mounted) return;
    final containerBox =
        _containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (containerBox == null) return;

    final center = _getCenterOffset(_centerKey, containerBox);
    if (center == Offset.zero) return;

    final connected = widget.connectedPlugins;
    if (connected.isEmpty) {
      setState(() {
        _beamPaths = [];
        _pathsCalculated = true;
      });
      return;
    }

    final displayList = connected.take(8).toList();
    final List<AnimatedBeamPath> newPaths = [];

    for (int i = 0; i < displayList.length; i++) {
      final item = displayList[i];
      final key = _nodeKeys[item.id];
      if (key == null) continue;
      final startPos = _getCenterOffset(key, containerBox);
      if (startPos == Offset.zero) continue;

      newPaths.add(AnimatedBeamPath(
        start: startPos,
        end: center,
        curvature: 0.0, 
        fromColor: item.primaryColor,
        toColor: item.secondaryColor,
        reverse: false,
      ));
    }

    setState(() {
      _beamPaths = newPaths;
      _pathsCalculated = true;
    });
  }

  Widget _buildNodeCircle({
    required GlobalKey key,
    required String toolId,
    required Widget icon,
    required String label,
    required Color glowColor,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onToolTap?.call(toolId);
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            key: key,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF141320),
              border: Border.all(
                color: glowColor.withValues(alpha: 0.35),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.25),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            padding: const EdgeInsets.all(9),
            child: Center(child: icon),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final connected = widget.connectedPlugins;
    final displayList = connected.take(8).toList();

    return Container(
      key: _containerKey,
      width: double.infinity,
      height: 300,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0B14),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_pathsCalculated && _beamPaths.isNotEmpty)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (context, _) {
                  return CustomPaint(
                    painter: AnimatedBeamPainter(
                      beams: _beamPaths,
                      progress: _ctrl.value,
                    ),
                  );
                },
              ),
            ),

          if (connected.isEmpty)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.heavyImpact();
                    widget.onCenterTap?.call();
                  },
                  child: Container(
                    key: _centerKey,
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF090812),
                      border: Border.all(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.20),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: JackOrb(
                        size: 58,
                        state: OrbState.idle,
                        enable3dTouch: false,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'No Plugins Connected',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Connect tools below to activate neural beams',
                  style: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            )
          else ...[
            GestureDetector(
              onTap: () {
                HapticFeedback.heavyImpact();
                widget.onCenterTap?.call();
              },
              child: Container(
                key: _centerKey,
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF090812),
                  border: Border.all(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.20),
                      blurRadius: 32,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: JackOrb(
                    size: 58,
                    state: OrbState.idle,
                    enable3dTouch: false,
                  ),
                ),
              ),
            ),
            
            ...displayList.asMap().entries.map((entry) {
              final int index = entry.key;
              final item = entry.value;
              final double angle = (index * 2 * 3.141592653589793) / displayList.length - 3.141592653589793 / 2;
              final double radius = 100.0;
              return Transform.translate(
                offset: Offset(radius * math.cos(angle), radius * math.sin(angle)),
                child: _buildNodeCircle(
                  key: _nodeKeys[item.id] ?? GlobalKey(),
                  toolId: item.id,
                  label: item.name,
                  glowColor: item.primaryColor,
                  icon: SvgPicture.asset(
                    item.svgAsset,
                    width: 22,
                    height: 22,
                  ),
                ),
              );
            }),
          ]
        ],
      ),
    );
  }
}
