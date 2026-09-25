// lib/widgets/animations/voice_pill.dart
//
// React Bits <VoicePill /> faithful Flutter implementation.
// Capsule microphone button with expanding waveform canvas, live timer (0:00),
// slide-to-cancel gesture (← Cancel), and morphing mic-to-stop indicator.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

enum VoicePillShape { pill, rounded }

class VoicePill extends StatefulWidget {
  final Color accentColor;
  final Color iconColor;
  final Color backgroundColor;
  final double size;
  final VoicePillShape shape;
  final bool showTime;
  final bool waveform;
  final bool slideToCancel;
  final double cancelDistance;
  final String reactive; // 'simulated' or 'mic'
  final bool disabled;
  final ValueChanged<String>? onStart;
  final void Function({required String reason, required Duration duration})? onStop;

  const VoicePill({
    super.key,
    this.accentColor = const Color(0xFFF5F5F5),
    this.iconColor = const Color(0xFFA1A1AA),
    this.backgroundColor = const Color(0xFF27272A),
    this.size = 38.0,
    this.shape = VoicePillShape.pill,
    this.showTime = true,
    this.waveform = true,
    this.slideToCancel = true,
    this.cancelDistance = 64.0,
    this.reactive = 'simulated',
    this.disabled = false,
    this.onStart,
    this.onStop,
  });

  @override
  State<VoicePill> createState() => _VoicePillState();
}

class _VoicePillState extends State<VoicePill> with TickerProviderStateMixin {
  bool _isListening = false;
  double _dragOffset = 0.0;
  DateTime? _startedAt;
  Timer? _clockTimer;
  String _formattedTime = '0:00';

  // Animation controllers
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  late AnimationController _waveController;

  // Audio level simulation & history
  final List<double> _levelHistory = [];
  double _currentLevel = 0.1;
  double _envelope = 0.0;
  int _tick = 0;

  static const double _loop = 4.8;
  static const List<List<double>> _syllables = [
    [0.1, 0.16, 0.9],
    [0.3, 0.12, 0.7],
    [0.5, 0.20, 1.0],
    [0.95, 0.14, 0.8],
    [1.15, 0.10, 0.6],
    [1.30, 0.22, 0.95],
    [1.90, 0.16, 0.85],
    [2.12, 0.12, 0.7],
    [2.30, 0.18, 0.9],
    [2.55, 0.10, 0.5],
    [3.05, 0.24, 1.0],
    [3.40, 0.12, 0.75],
    [3.60, 0.16, 0.9],
  ];

  @override
  void initState() {
    super.initState();

    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..addListener(_onWaveTick);
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _expandController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _onWaveTick() {
    if (!_isListening) return;

    final nowSec = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final t = nowSec % _loop;

    // React Bits syllable waveform math
    double a = 0.06;
    for (final s in _syllables) {
      final start = s[0];
      final dur = s[1];
      final peak = s[2];
      final x = (t - start) / dur;
      if (x >= 0.0 && x <= 1.0) {
        final val = peak * 0.5 * (1.0 - math.cos(2 * math.pi * x));
        if (val > a) a = val;
      }
    }
    final target = a * (0.7 + 0.3 * (math.sin(2 * math.pi * 7.1 * t).abs()));

    // Envelope follower
    _envelope += (target - _envelope) * 0.35;
    _currentLevel = _envelope;

    _tick = (_tick + 1) % 4;
    if (_tick == 0) {
      _levelHistory.add(_currentLevel);
      if (_levelHistory.length > 50) {
        _levelHistory.removeAt(0);
      }
      if (mounted) setState(() {});
    }
  }

  void _start() {
    if (widget.disabled || _isListening) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _isListening = true;
      _dragOffset = 0.0;
      _startedAt = DateTime.now();
      _formattedTime = '0:00';
      _levelHistory.clear();
      _envelope = 0.1;
    });

    _expandController.forward();
    _waveController.repeat();

    _clockTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_startedAt == null || !mounted) return;
      final elapsed = DateTime.now().difference(_startedAt!);
      final m = elapsed.inMinutes;
      final s = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
      setState(() {
        _formattedTime = '$m:$s';
      });
    });

    widget.onStart?.call(widget.reactive);
  }

  void _stop({String reason = 'tap'}) {
    if (!_isListening) return;

    HapticFeedback.lightImpact();
    final duration = _startedAt != null
        ? DateTime.now().difference(_startedAt!)
        : Duration.zero;

    _clockTimer?.cancel();
    _waveController.stop();
    _expandController.reverse();

    setState(() {
      _isListening = false;
      _dragOffset = 0.0;
    });

    widget.onStop?.call(reason: reason, duration: duration);
  }

  @override
  Widget build(BuildContext context) {
    final pillRadius = widget.shape == VoicePillShape.rounded
        ? widget.size * 0.28
        : widget.size / 2;

    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        final progress = _expandAnimation.value;
        final cancelProgress = (_dragOffset / widget.cancelDistance).clamp(0.0, 1.0);

        // Expanded width calculation
        final baseWidth = widget.size;
        final fullWidth = widget.size +
            (widget.waveform ? 44.0 : 0.0) +
            (widget.showTime ? 34.0 : 0.0) +
            (widget.slideToCancel ? 40.0 : 0.0);

        final currentWidth = baseWidth + (fullWidth - baseWidth) * progress;

        final bgColor = Color.lerp(
          widget.backgroundColor,
          const Color(0xFFEF4444).withValues(alpha: 0.25),
          cancelProgress,
        )!;

        return GestureDetector(
          onTap: () {
            if (_isListening) {
              _stop(reason: 'tap');
            } else {
              _start();
            }
          },
          onHorizontalDragUpdate: widget.slideToCancel && _isListening
              ? (details) {
                  setState(() {
                    _dragOffset = (_dragOffset - details.delta.dx)
                        .clamp(0.0, widget.cancelDistance + 24.0);
                  });
                  if (_dragOffset >= widget.cancelDistance) {
                    _stop(reason: 'cancel');
                  }
                }
              : null,
          onHorizontalDragEnd: widget.slideToCancel && _isListening
              ? (_) {
                  if (_dragOffset >= widget.cancelDistance) {
                    _stop(reason: 'cancel');
                  } else {
                    setState(() => _dragOffset = 0.0);
                  }
                }
              : null,
          child: Container(
            height: widget.size,
            width: currentWidth,
            transform: Matrix4.translationValues(-_dragOffset * 0.4, 0, 0),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(pillRadius),
              border: Border.all(
                color: _isListening
                    ? Color.lerp(
                        widget.accentColor.withValues(alpha: 0.35),
                        const Color(0xFFEF4444),
                        cancelProgress,
                      )!
                    : Colors.white.withValues(alpha: 0.12),
                width: 1.2,
              ),
              boxShadow: [
                if (_isListening)
                  BoxShadow(
                    color: Color.lerp(
                      widget.accentColor.withValues(alpha: 0.2),
                      const Color(0xFFEF4444).withValues(alpha: 0.3),
                      cancelProgress,
                    )!,
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(pillRadius),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Slide to cancel hint
                  if (widget.slideToCancel && progress > 0.6) ...[
                    Opacity(
                      opacity: (progress * (1.0 - cancelProgress * 0.5))
                          .clamp(0.0, 1.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_back_rounded,
                            size: 13,
                            color: Color.lerp(
                              widget.iconColor,
                              const Color(0xFFEF4444),
                              cancelProgress,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              color: Color.lerp(
                                widget.iconColor,
                                const Color(0xFFEF4444),
                                cancelProgress,
                              ),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Real-time audio waveform canvas
                  if (widget.waveform && progress > 0.4) ...[
                    Expanded(
                      child: Opacity(
                        opacity: progress,
                        child: CustomPaint(
                          size: Size(double.infinity, widget.size * 0.6),
                          painter: _WaveformPainter(
                            history: _levelHistory,
                            accentColor: widget.accentColor,
                            floor: 0.12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],

                  // Elapsed Stopwatch (0:00)
                  if (widget.showTime && progress > 0.5) ...[
                    Opacity(
                      opacity: progress,
                      child: Text(
                        _formattedTime,
                        style: GoogleFonts.robotoMono(
                          color: widget.accentColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Mic Icon morphing to Stop Square
                  SizedBox(
                    width: math.max(0.0, widget.size - 2.4),
                    height: math.max(0.0, widget.size - 2.4),
                    child: Center(
                      child: AnimatedCrossFade(
                        duration: const Duration(milliseconds: 180),
                        crossFadeState: _isListening
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        firstChild: Icon(
                          Icons.mic_rounded,
                          color: widget.iconColor,
                          size: widget.size * 0.50,
                        ),
                        secondChild: Container(
                          width: widget.size * 0.30,
                          height: widget.size * 0.30,
                          decoration: BoxDecoration(
                            color: widget.accentColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> history;
  final Color accentColor;
  final double floor;

  _WaveformPainter({
    required this.history,
    required this.accentColor,
    required this.floor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    final barWidth = 2.2;
    final step = 3.6;
    final height = size.height;
    final width = size.width;

    final paint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    for (int i = 0; i < history.length; i++) {
      final v = history[history.length - 1 - i];
      final x = width - (i + 1) * step;
      if (x + barWidth < 0) break;

      final barH = math.max(barWidth, (floor + (1.0 - floor) * v) * height);
      final y = (height - barH) / 2;

      // Left-side fadeout
      final t = (x / (width * 0.55)).clamp(0.0, 1.0);
      final fade = t * t * (3.0 - 2.0 * t);
      final alpha = ((0.35 + 0.65 * v) * fade).clamp(0.0, 1.0);

      paint.color = accentColor.withValues(alpha: alpha);
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barH),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(rrect, paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) => true;
}
