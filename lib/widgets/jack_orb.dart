// lib/widgets/jack_orb.dart
//
// Animated JACK Orb — Pixel-perfect 3D celestial glowing orb with
// multi-layer volumetric gradient, ambient dual-tone bloom,
// glowing twin capsule eyes with parallax sensor tracking, and
// fully interactive 3D touch rotation, dragging, and haptic feedback.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

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
  late AnimationController _springCtrl;
  late Animation<double> _breatheAnim;

  StreamSubscription<AccelerometerEvent>? _accelSub;
  double _eyeOffsetX = 0.0;
  double _eyeOffsetY = 0.0;
  double _targetOffsetX = 0.0;
  double _targetOffsetY = 0.0;

  // 3D rotation angles (radians) driven by finger drag
  double _pitch = 0.0;
  double _yaw = 0.0;

  Animation<double>? _pitchAnim;
  Animation<double>? _yawAnim;

  late AnimationController _saccadeCtrl;
  Animation<Offset>? _saccadeAnim;
  Timer? _saccadeTimer;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _breatheCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _springCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _saccadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _breatheAnim = Tween<double>(begin: 0.96, end: 1.02).animate(
      CurvedAnimation(parent: _breatheCtrl, curve: Curves.easeInOut),
    );

    _initSensors();
    _startAutonomousSaccades();
  }

  void _startAutonomousSaccades() {
    _saccadeTimer?.cancel();
    _saccadeTimer = Timer.periodic(const Duration(milliseconds: 3200), (timer) {
      if (!mounted) return;
      if (_springCtrl.isAnimating) return;

      // Only perform natural saccades when idle
      final maxOffset = widget.size * 0.055;
      final shouldGlance = _rng.nextBool();
      final target = shouldGlance
          ? Offset(
              (_rng.nextDouble() * 2 - 1) * maxOffset * 0.7,
              (_rng.nextDouble() * 1.5 - 0.3) * maxOffset * 0.6,
            )
          : Offset.zero;

      _saccadeAnim = Tween<Offset>(
        begin: Offset(_eyeOffsetX, _eyeOffsetY),
        end: target,
      ).animate(CurvedAnimation(parent: _saccadeCtrl, curve: Curves.easeInOutCubic));

      _saccadeCtrl.reset();
      _saccadeCtrl.forward();
      _saccadeCtrl.addListener(() {
        if (_saccadeAnim != null && mounted) {
          setState(() {
            _eyeOffsetX = _saccadeAnim!.value.dx;
            _eyeOffsetY = _saccadeAnim!.value.dy;
          });
        }
      });
    });
  }

  void _initSensors() {
    try {
      _accelSub = accelerometerEventStream().listen((AccelerometerEvent event) {
        if (!mounted) return;
        // Sensitivity scaled with size
        final maxOffset = widget.size * 0.035;
        _targetOffsetX = -event.x.clamp(-4.0, 4.0) * (maxOffset / 4.0);
        _targetOffsetY = (event.y - 5.0).clamp(-4.0, 4.0) * (maxOffset / 4.0);

        setState(() {
          _eyeOffsetX += (_targetOffsetX - _eyeOffsetX) * 0.15;
          _eyeOffsetY += (_targetOffsetY - _eyeOffsetY) * 0.15;
        });
      });
    } catch (e) {
      debugPrint('Sensors not available on this device: $e');
    }
  }

  void _onPanStart(DragStartDetails details) {
    _springCtrl.stop();
    HapticFeedback.selectionClick();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    // 1 pixel drag = ~0.008 radians
    setState(() {
      _yaw = (_yaw + details.delta.dx * 0.009).clamp(-1.2, 1.2);
      _pitch = (_pitch - details.delta.dy * 0.009).clamp(-0.8, 0.8);

      // Dynamically offset eyes toward the touch motion
      final maxOffset = widget.size * 0.06;
      _eyeOffsetX = (_yaw / 1.2) * maxOffset;
      _eyeOffsetY = (-_pitch / 0.8) * maxOffset;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _springCtrl.reset();
    _pitchAnim = Tween<double>(begin: _pitch, end: 0.0).animate(
      CurvedAnimation(parent: _springCtrl, curve: Curves.elasticOut),
    );
    _yawAnim = Tween<double>(begin: _yaw, end: 0.0).animate(
      CurvedAnimation(parent: _springCtrl, curve: Curves.elasticOut),
    );

    _springCtrl.forward();
    _springCtrl.addListener(() {
      if (_pitchAnim != null && _yawAnim != null) {
        setState(() {
          _pitch = _pitchAnim!.value;
          _yaw = _yawAnim!.value;
          final maxOffset = widget.size * 0.06;
          _eyeOffsetX = (_yaw / 1.2) * maxOffset;
          _eyeOffsetY = (-_pitch / 0.8) * maxOffset;
        });
      }
    });
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _saccadeTimer?.cancel();
    _saccadeCtrl.dispose();
    _breatheCtrl.dispose();
    _rotateCtrl.dispose();
    _pulseCtrl.dispose();
    _springCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onTap?.call();
      },
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([_breatheCtrl, _rotateCtrl, _pulseCtrl, _springCtrl]),
        builder: (context, child) {
          final scale = _breatheAnim.value;

          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.0018) // 3D Perspective projection
            ..rotateX(_pitch)
            ..rotateY(_yaw);

          return Transform.scale(
            scale: scale,
            child: Transform(
              alignment: Alignment.center,
              transform: transform,
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _JackOrbPainter(
                    progress: _rotateCtrl.value,
                    pulse: _pulseCtrl.value,
                    eyeOffsetX: _eyeOffsetX,
                    eyeOffsetY: _eyeOffsetY,
                    state: widget.state,
                    pitch: _pitch,
                    yaw: _yaw,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _JackOrbPainter extends CustomPainter {
  final double progress;
  final double pulse;
  final double eyeOffsetX;
  final double eyeOffsetY;
  final OrbState state;
  final double pitch;
  final double yaw;

  _JackOrbPainter({
    required this.progress,
    required this.pulse,
    required this.eyeOffsetX,
    required this.eyeOffsetY,
    required this.state,
    this.pitch = 0.0,
    this.yaw = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.44; // Sphere radius (leaving padding for ambient glow)
    final sphereRect = Rect.fromCircle(center: center, radius: radius);

    // ── 1. Dual-Tone Ambient Background Bloom ─────────────────────────────
    _paintAmbientBloom(canvas, center, radius);

    // ── 2. Volumetric Spherical Plasma Body ───────────────────────────────
    canvas.save();
    final spherePath = Path()..addOval(sphereRect);
    canvas.clipPath(spherePath);

    _paintSphereBody(canvas, sphereRect, center, radius);

    canvas.restore();

    // ── 3. Luminous Outer Rim Light ───────────────────────────────────────
    _paintRimLight(canvas, sphereRect, center, radius);

    // ── 4. Glowing Twin Capsule Eyes ──────────────────────────────────────
    _paintTwinCapsuleEyes(canvas, center, radius);
  }

  void _paintAmbientBloom(Canvas canvas, Offset center, double radius) {
    switch (state) {
      case OrbState.thinking:
        final glow = Paint()
          ..color = const Color(0xFF7C3AED).withValues(alpha: 0.35 + 0.08 * pulse)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.45);
        canvas.drawCircle(center, radius * 0.85, glow);
        break;

      case OrbState.working:
        final glow = Paint()
          ..color = const Color(0xFF00E5FF).withValues(alpha: 0.40 + 0.08 * pulse)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.45);
        canvas.drawCircle(center, radius * 0.85, glow);
        break;

      case OrbState.success:
        final glow = Paint()
          ..color = const Color(0xFF10B981).withValues(alpha: 0.40 + 0.08 * pulse)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.45);
        canvas.drawCircle(center, radius * 0.85, glow);
        break;

      case OrbState.error:
        final glow = Paint()
          ..color = const Color(0xFFEF4444).withValues(alpha: 0.40 + 0.08 * pulse)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.45);
        canvas.drawCircle(center, radius * 0.85, glow);
        break;

      case OrbState.listening:
      case OrbState.idle:
        // Left Ambient Pink Bloom
        final leftBloom = Paint()
          ..color = const Color(0xFFEC4899).withValues(alpha: 0.36 + 0.06 * pulse)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.50);
        canvas.drawCircle(
          Offset(center.dx - radius * 0.38 + yaw * 10, center.dy - pitch * 10),
          radius * 0.80,
          leftBloom,
        );

        // Bottom-Left Warm Golden Peach Sunrise Bloom (matches reference image)
        final peachBloom = Paint()
          ..color = const Color(0xFFFFD166).withValues(alpha: 0.28 + 0.05 * pulse)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.45);
        canvas.drawCircle(
          Offset(center.dx - radius * 0.38 + yaw * 8, center.dy + radius * 0.32 - pitch * 8),
          radius * 0.65,
          peachBloom,
        );

        // Right Ambient Cyan Bloom
        final rightBloom = Paint()
          ..color = const Color(0xFF00E5FF).withValues(alpha: 0.42 + 0.06 * pulse)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.50);
        canvas.drawCircle(
          Offset(center.dx + radius * 0.38 + yaw * 10, center.dy - pitch * 10),
          radius * 0.80,
          rightBloom,
        );
        break;
    }
  }

  void _paintSphereBody(Canvas canvas, Rect sphereRect, Offset center, double radius) {
    if (state == OrbState.idle || state == OrbState.listening) {
      // ── Idle/Listening: Reference Image Exact Luminous Palette ───────────

      // Layer 1: Base Linear Celestial Flow with tilt offset
      final baseGradient = LinearGradient(
        begin: Alignment(-1.0 + yaw * 0.3, -0.3 + pitch * 0.3),
        end: Alignment(1.0 + yaw * 0.3, 0.3 + pitch * 0.3),
        colors: const [
          Color(0xFFF472B6), // Soft radiant magenta / pink
          Color(0xFFE879F9), // Lilac / orchid
          Color(0xFF818CF8), // Periwinkle / indigo
          Color(0xFF38BDF8), // Sky blue
          Color(0xFF00E5FF), // Electric cyan
        ],
        stops: const [0.0, 0.26, 0.52, 0.78, 1.0],
      );
      final basePaint = Paint()..shader = baseGradient.createShader(sphereRect);
      canvas.drawRect(sphereRect, basePaint);

      // Layer 2: Radiant Cyan Dome (Right Side)
      final cyanCore = Paint()
        ..shader = RadialGradient(
          center: Alignment(0.68 + yaw * 0.3, 0.04 - pitch * 0.3),
          radius: 0.88,
          colors: [
            const Color(0xFF00E5FF).withValues(alpha: 0.96),
            const Color(0xFF0284C7).withValues(alpha: 0.65),
            const Color(0xFF0369A1).withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(sphereRect);
      canvas.drawRect(sphereRect, cyanCore);

      // Layer 3: Vibrant Magenta Core (Left Side)
      final magentaCore = Paint()
        ..shader = RadialGradient(
          center: Alignment(-0.68 + yaw * 0.3, -0.18 - pitch * 0.3),
          radius: 0.92,
          colors: [
            const Color(0xFFEC4899).withValues(alpha: 0.95),
            const Color(0xFFA855F7).withValues(alpha: 0.65),
            const Color(0xFF7C3AED).withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.58, 1.0],
        ).createShader(sphereRect);
      canvas.drawRect(sphereRect, magentaCore);

      // Layer 4: Warm Golden Peach Sunrise Glow (Bottom-Left Edge)
      final peachGlow = Paint()
        ..shader = RadialGradient(
          center: Alignment(-0.78 + yaw * 0.25, 0.68 - pitch * 0.25),
          radius: 0.72,
          colors: [
            const Color(0xFFFFD166).withValues(alpha: 0.88),
            const Color(0xFFFB923C).withValues(alpha: 0.45),
            Colors.transparent,
          ],
          stops: const [0.0, 0.50, 1.0],
        ).createShader(sphereRect);
      canvas.drawRect(sphereRect, peachGlow);

      // Layer 5: Central Spherical Depth Core (Indigo Depth)
      final depthCore = Paint()
        ..shader = RadialGradient(
          center: Alignment(0.0 + yaw * 0.2, -0.06 - pitch * 0.2),
          radius: 0.65,
          colors: [
            const Color(0xFF3B82F6).withValues(alpha: 0.35),
            const Color(0xFF1E1B4B).withValues(alpha: 0.20),
            Colors.transparent,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(sphereRect);
      canvas.drawRect(sphereRect, depthCore);
    } else {
      // ── Other States: Dynamic Themed Spheres ─────────────────────────────
      List<Color> palette;
      switch (state) {
        case OrbState.thinking:
          palette = const [Color(0xFF7C3AED), Color(0xFF3B82F6), Color(0xFF00E5FF)];
          break;
        case OrbState.working:
          palette = const [Color(0xFF00E5FF), Color(0xFF06B6D4), Color(0xFF10B981)];
          break;
        case OrbState.success:
          palette = const [Color(0xFF10B981), Color(0xFF06B6D4), Color(0xFF3B82F6)];
          break;
        case OrbState.error:
          palette = const [Color(0xFFEF4444), Color(0xFFF43F5E), Color(0xFFF59E0B)];
          break;
        default:
          palette = const [Color(0xFFF472B6), Color(0xFF3B82F6), Color(0xFF00E5FF)];
      }

      final gradient = SweepGradient(
        transform: GradientRotation(progress * 2 * pi + yaw),
        colors: [...palette, palette.first],
      );
      final p = Paint()..shader = gradient.createShader(sphereRect);
      canvas.drawRect(sphereRect, p);

      final highlight = Paint()
        ..shader = RadialGradient(
          center: Alignment(-0.2 + yaw * 0.3, -0.3 - pitch * 0.3),
          radius: 0.85,
          colors: [
            Colors.white.withValues(alpha: 0.3),
            Colors.transparent,
          ],
        ).createShader(sphereRect);
      canvas.drawRect(sphereRect, highlight);
    }
  }

  void _paintRimLight(Canvas canvas, Rect sphereRect, Offset center, double radius) {
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8)
      ..shader = SweepGradient(
        transform: GradientRotation(yaw * 0.5),
        colors: const [
          Color(0xFF00E5FF),
          Color(0xFF38BDF8),
          Color(0xFFFFD166),
          Color(0xFFEC4899),
          Color(0xFFE879F9),
          Color(0xFF00E5FF),
        ],
      ).createShader(sphereRect);

    canvas.drawCircle(center, radius - 1.0, rimPaint);
  }

  void _paintTwinCapsuleEyes(Canvas canvas, Offset center, double radius) {
    final eyeCenterX = center.dx + eyeOffsetX;
    final eyeCenterY = center.dy + eyeOffsetY;

    // Dimensions matching reference image (sleek vertical pills)
    final eyeHeight = radius * 0.38;
    final eyeWidth = radius * 0.12;
    final eyeSpacing = radius * 0.28; // Distance between centers
    final cornerRadius = Radius.circular(eyeWidth / 2);

    final leftRect = Rect.fromCenter(
      center: Offset(eyeCenterX - eyeSpacing / 2, eyeCenterY),
      width: eyeWidth,
      height: eyeHeight,
    );
    final rightRect = Rect.fromCenter(
      center: Offset(eyeCenterX + eyeSpacing / 2, eyeCenterY),
      width: eyeWidth,
      height: eyeHeight,
    );

    final leftRRect = RRect.fromRectAndRadius(leftRect, cornerRadius);
    final rightRRect = RRect.fromRectAndRadius(rightRect, cornerRadius);

    final eyeGlowColor = state == OrbState.error
        ? const Color(0xFFEF4444)
        : state == OrbState.success
            ? const Color(0xFF10B981)
            : const Color(0xFF00E5FF);

    // Pass 1: Broad Diffuse Cyan Neon Bloom
    final outerBloom = Paint()
      ..color = eyeGlowColor.withValues(alpha: 0.50 + 0.10 * pulse)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.18);
    canvas.drawRRect(leftRRect, outerBloom);
    canvas.drawRRect(rightRRect, outerBloom);

    // Pass 2: Intense Focused Neon Cyan Aura
    final midBloom = Paint()
      ..color = eyeGlowColor.withValues(alpha: 0.90)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.08);
    canvas.drawRRect(leftRRect, midBloom);
    canvas.drawRRect(rightRRect, midBloom);

    // Pass 3: Radiant White / Pale Cyan Core Aura
    final whiteBloom = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.032);
    canvas.drawRRect(leftRRect, whiteBloom);
    canvas.drawRRect(rightRRect, whiteBloom);

    // Pass 4: Solid Pure White Capsule Core
    final coreFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRRect(leftRRect, coreFill);
    canvas.drawRRect(rightRRect, coreFill);
  }

  @override
  bool shouldRepaint(covariant _JackOrbPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.pulse != pulse ||
        oldDelegate.eyeOffsetX != eyeOffsetX ||
        oldDelegate.eyeOffsetY != eyeOffsetY ||
        oldDelegate.state != state ||
        oldDelegate.pitch != pitch ||
        oldDelegate.yaw != yaw;
  }
}
