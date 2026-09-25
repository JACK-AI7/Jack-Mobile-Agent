// lib/widgets/animations/thought_line.dart
//
// React Bits <ThoughtLine /> faithful Flutter implementation.
// Breathing AI reasoning line with shimmer text gradient, live decisecond stopwatch,
// settle morph ("Thought for 2.3s"), and collapsible multi-agent step trace.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class ThoughtLineStep {
  final String text;
  final bool isDone;
  final Color? color;

  const ThoughtLineStep({
    required this.text,
    this.isDone = true,
    this.color,
  });
}

class ThoughtLine extends StatefulWidget {
  final String label;
  final String? doneLabel;
  final String glyph; // 'sparkle', 'dot', or 'none'
  final List<ThoughtLineStep> steps;
  final bool collapsible;
  final bool collapseOnSettle;
  final Color color;
  final Color? glyphColor;
  final double fontSize;
  final Duration breathPeriod;
  final double breathDepth;
  final bool shimmer;
  final bool working;
  final bool showTimer;
  final double? elapsed;
  final ValueChanged<double>? onSettle;

  const ThoughtLine({
    super.key,
    this.label = 'Thinking…',
    this.doneLabel,
    this.glyph = 'sparkle',
    this.steps = const [],
    this.collapsible = true,
    this.collapseOnSettle = true,
    this.color = Colors.white,
    this.glyphColor,
    this.fontSize = 13.5,
    this.breathPeriod = const Duration(milliseconds: 1600),
    this.breathDepth = 0.45,
    this.shimmer = true,
    this.working = true,
    this.showTimer = true,
    this.elapsed,
    this.onSettle,
  });

  @override
  State<ThoughtLine> createState() => _ThoughtLineState();
}

class _ThoughtLineState extends State<ThoughtLine> with TickerProviderStateMixin {
  late AnimationController _breatheController;
  late Animation<double> _breatheAnimation;

  late AnimationController _shimmerController;

  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  bool _isExpanded = false;
  Timer? _stopwatchTimer;
  int _deciseconds = 0;
  DateTime? _startedAt;

  @override
  void initState() {
    super.initState();

    // Breathing loop
    _breatheController = AnimationController(
      vsync: this,
      duration: widget.breathPeriod,
    )..repeat(reverse: true);

    _breatheAnimation = Tween<double>(
      begin: 1.0 - widget.breathDepth,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _breatheController,
      curve: Curves.easeInOutSine,
    ));

    // Shimmer sweep loop
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // Trace expand/collapse
    _isExpanded = widget.working && widget.steps.isNotEmpty;
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      value: _isExpanded ? 1.0 : 0.0,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOutCubic,
    );

    _initTimer();
  }

  void _initTimer() {
    if (widget.elapsed != null) {
      _deciseconds = (widget.elapsed! * 10).round();
      return;
    }

    if (widget.working) {
      _startedAt = DateTime.now();
      _deciseconds = 0;
      _stopwatchTimer?.cancel();
      _stopwatchTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
        if (!mounted || !widget.working) {
          t.cancel();
          return;
        }
        setState(() {
          _deciseconds =
              (DateTime.now().difference(_startedAt!).inMilliseconds / 100).floor();
        });
      });
    }
  }

  @override
  void didUpdateWidget(ThoughtLine oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.working != oldWidget.working) {
      if (widget.working) {
        _initTimer();
        _breatheController.repeat(reverse: true);
        _shimmerController.repeat();
        if (widget.steps.isNotEmpty) {
          _expandController.forward();
          _isExpanded = true;
        }
      } else {
        _stopwatchTimer?.cancel();
        _breatheController.stop();
        _shimmerController.stop();
        widget.onSettle?.call(_deciseconds / 10.0);

        if (widget.collapseOnSettle) {
          _expandController.reverse();
          _isExpanded = false;
        }
      }
    }
  }

  @override
  void dispose() {
    _stopwatchTimer?.cancel();
    _breatheController.dispose();
    _shimmerController.dispose();
    _expandController.dispose();
    super.dispose();
  }

  String _formatTimer(int ds) {
    if (ds < 600) {
      return '${(ds / 10.0).toStringAsFixed(1)}s';
    }
    final mins = ds ~/ 600;
    final remSecs = (ds % 600) / 10.0;
    return '${mins}m ${remSecs.toStringAsFixed(1)}s';
  }

  void _toggleExpand() {
    if (!widget.collapsible || widget.steps.isEmpty) return;

    HapticFeedback.selectionClick();
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final effectiveGlyphColor =
        widget.glyphColor ?? const Color(0xFF00E5FF);
    final hasTrace = widget.steps.isNotEmpty;
    final doneText =
        widget.doneLabel ?? (widget.showTimer ? 'Thought for' : 'Done thinking');

    return Container(
      decoration: widget.working ? BoxDecoration(
        color: const Color(0xFF141320),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: effectiveGlyphColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ) : const BoxDecoration(),
      padding: widget.working 
          ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10)
          : const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header Row ──────────────────────────────────────────────────
          GestureDetector(
            onTap: hasTrace ? _toggleExpand : null,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                // Glyph (Sparkle or Dot)
                if (widget.glyph != 'none') ...[
                  AnimatedBuilder(
                    animation: _breatheAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: widget.working
                            ? _breatheAnimation.value
                            : 0.65,
                        child: widget.glyph == 'dot'
                            ? Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: effectiveGlyphColor,
                                ),
                              )
                            : Icon(
                                Icons.auto_awesome_rounded,
                                size: widget.fontSize + 2,
                                color: effectiveGlyphColor,
                              ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],

                // Shimmering or Settle text
                Expanded(
                  child: widget.working && widget.shimmer
                      ? AnimatedBuilder(
                          animation: _shimmerController,
                          builder: (context, child) {
                            return ShaderMask(
                              shaderCallback: (bounds) {
                                return LinearGradient(
                                  colors: [
                                    effectiveGlyphColor,
                                    Colors.white,
                                    const Color(0xFF7C3AED),
                                    effectiveGlyphColor,
                                  ],
                                  stops: const [0.0, 0.45, 0.75, 1.0],
                                  transform: _ShimmerTranslate(
                                      _shimmerController.value),
                                ).createShader(bounds);
                              },
                              child: Text(
                                widget.label,
                                style: GoogleFonts.inter(
                                  color: widget.color,
                                  fontSize: widget.fontSize,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          },
                        )
                      : Text(
                          widget.working ? widget.label : doneText,
                          style: GoogleFonts.inter(
                            color: widget.color.withValues(
                                alpha: widget.working ? 1.0 : 0.8),
                            fontSize: widget.fontSize,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),

                // Timer badge
                if (widget.showTimer) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _formatTimer(_deciseconds),
                      style: GoogleFonts.robotoMono(
                        color: widget.working
                            ? effectiveGlyphColor
                            : Colors.white70,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],

                // Chevron for collapsible trace
                if (hasTrace && widget.collapsible) ...[
                  const SizedBox(width: 6),
                  RotationTransition(
                    turns: Tween<double>(begin: 0.0, end: 0.5)
                        .animate(_expandAnimation),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white54,
                      size: 18,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Collapsible Steps Trace ─────────────────────────────────────
          if (hasTrace)
            SizeTransition(
              sizeFactor: _expandAnimation,
              child: Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C0B16),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Column(
                    children: widget.steps.map((step) {
                      final stepColor =
                          step.color ?? const Color(0xFF00E5FF);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              alignment: Alignment.center,
                              child: step.isDone
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 14,
                                      color: Color(0xFF22C55E),
                                    )
                                  : Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: stepColor,
                                        boxShadow: [
                                          BoxShadow(
                                            color: stepColor.withValues(alpha: 0.6),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                step.text,
                                style: GoogleFonts.inter(
                                  color: step.isDone
                                      ? Colors.white70
                                      : stepColor,
                                  fontSize: 12,
                                  fontWeight: step.isDone
                                      ? FontWeight.w400
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ShimmerTranslate extends GradientTransform {
  final double progress;
  const _ShimmerTranslate(this.progress);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (progress * 2.0 - 1.0), 0, 0);
  }
}
