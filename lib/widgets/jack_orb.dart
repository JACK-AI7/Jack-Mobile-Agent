// lib/widgets/jack_orb.dart
//
// Animated JACK orb — 6 states with GPU-friendly animations and Accelerometer eye-tracking
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../theme/app_colors.dart';

enum OrbState { idle, thinking, working, success, error, listening }

class JackOrb extends StatefulWidget {
  final OrbState state;
  final double size;
  final VoidCallback? onTap;

  const JackOrb({
    super.key,
    this.state = OrbState.idle,
    this.size = 120,
    this.onTap,
  });

  @override
  State<JackOrb> createState() => _JackOrbState();
}

class _JackOrbState extends State<JackOrb> with TickerProviderStateMixin {
  late AnimationController _breatheCtrl;
  late AnimationController _rotateCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _breatheAnim;

  StreamSubscription<AccelerometerEvent>? _accelSub;
  double _eyeOffsetX = 0.0;
  double _eyeOffsetY = 0.0;
  double _targetOffsetX = 0.0;
  double _targetOffsetY = 0.0;

  @override
  void initState() {
    super.initState();
    _breatheCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _breatheAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _breatheCtrl, curve: Curves.easeInOut),
    );

    _initSensors();
  }

  void _initSensors() {
    try {
      _accelSub = accelerometerEventStream().listen((AccelerometerEvent event) {
        if (!mounted) return;
        // The event values usually range from -9.8 to 9.8 (gravity)
        // We invert X so when tilted right, eyes go right.
        _targetOffsetX = -event.x.clamp(-4.0, 4.0) * (widget.size * 0.025);
        // We invert Y so when tilted up (negative y), eyes go up.
        _targetOffsetY = (event.y - 5.0).clamp(-4.0, 4.0) * (widget.size * 0.025);

        // Smooth interpolation
        setState(() {
          _eyeOffsetX += (_targetOffsetX - _eyeOffsetX) * 0.15;
          _eyeOffsetY += (_targetOffsetY - _eyeOffsetY) * 0.15;
        });
      });
    } catch (e) {
      debugPrint('Sensors not available on this device: $e');
    }
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _breatheCtrl.dispose();
    _rotateCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  List<Color> get _stateColors {
    switch (widget.state) {
      case OrbState.thinking:
        return [AppColors.accentViolet, AppColors.accentBlue, AppColors.accentCyan];
      case OrbState.working:
        return [AppColors.accentCyan, AppColors.accentTeal, AppColors.accentBlue];
      case OrbState.success:
        return [AppColors.success, AppColors.accentTeal, AppColors.accentCyan];
      case OrbState.error:
        return [AppColors.error, AppColors.accentPink, AppColors.accentViolet];
      case OrbState.listening:
        return [AppColors.accentPink, AppColors.accentViolet, AppColors.accentCyan];
      case OrbState.idle:
        return AppColors.orbGradient;
    }
  }

  Color get _glowColor {
    switch (widget.state) {
      case OrbState.thinking: return AppColors.accentViolet;
      case OrbState.working:  return AppColors.accentCyan;
      case OrbState.success:  return AppColors.success;
      case OrbState.error:    return AppColors.error;
      case OrbState.listening: return AppColors.accentPink;
      default:                return AppColors.accentCyan;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_breatheCtrl, _rotateCtrl, _pulseCtrl]),
        builder: (context, child) {
          final scale = widget.state == OrbState.idle ? _breatheAnim.value : 1.0;
          final glowRadius = widget.size * 0.35 +
              (widget.state == OrbState.listening
                  ? _pulseCtrl.value * widget.size * 0.2
                  : 0);

          return Transform.scale(
            scale: scale,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // ── Outer glow ────────────────────────────────────────────
                  Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _glowColor.withValues(alpha: 0.25),
                          blurRadius: glowRadius,
                          spreadRadius: glowRadius * 0.3,
                        ),
                      ],
                    ),
                  ),

                  // ── Rotating gradient ring ────────────────────────────────
                  Transform.rotate(
                    angle: _rotateCtrl.value * 2 * pi,
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            ..._stateColors,
                            _stateColors.first,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Inner orb body ────────────────────────────────────────
                  Container(
                    width: widget.size * 0.88,
                    height: widget.size * 0.88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: const Alignment(-0.3, -0.4),
                        colors: [
                          _stateColors.first.withValues(alpha: 0.8),
                          const Color(0xFF0A0A20),
                          const Color(0xFF050510),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),

                  // ── Specular highlight ────────────────────────────────────
                  Positioned(
                    top: widget.size * 0.12,
                    left: widget.size * 0.15,
                    child: Container(
                      width: widget.size * 0.3,
                      height: widget.size * 0.15,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(widget.size),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.35),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Jack "eyes" (with parallax effect) ─────────────────────
                  Transform.translate(
                    offset: Offset(_eyeOffsetX, _eyeOffsetY),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _Eye(
                          size: widget.size * 0.065,
                          blinking: widget.state == OrbState.idle,
                          pulseCtrl: _pulseCtrl,
                        ),
                        SizedBox(width: widget.size * 0.1),
                        _Eye(
                          size: widget.size * 0.065,
                          blinking: widget.state == OrbState.idle,
                          pulseCtrl: _pulseCtrl,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Eye extends StatelessWidget {
  final double size;
  final bool blinking;
  final AnimationController pulseCtrl;

  const _Eye({required this.size, this.blinking = false, required this.pulseCtrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * 0.7,
      height: size * 2.2,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(size),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.6),
            blurRadius: size * 1.5,
          ),
        ],
      ),
    );
  }
}
