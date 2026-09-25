// lib/widgets/animations/lattice_loader.dart
//
// Flutter implementation of React Bits' <LatticeLoader /> component
// (https://reactbits.dev/components/lattice-loader)
// Complete with all 3x3 and 4x4 patterns (orbit, arrow, dots, ripple, spiral, snake,
// sweep, spin, rain, pulse), mark dissolves (done checkmark, error cross),
// live stopwatch timer, customizable cell size, gap, glow, and shapes.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum LatticeStatus { working, done, error }

enum LatticeShape { round, square }

class LatticePatternData {
  final List<int?> cells;
  final double loop;
  final double scale;
  final double lit;

  const LatticePatternData({
    required this.cells,
    required this.loop,
    required this.scale,
    this.lit = 0.62,
  });
}

class LatticeLoader extends StatefulWidget {
  final String label;
  final String doneLabel;
  final String errorLabel;
  final LatticeStatus status;
  final String pattern;
  final int grid; // 3 or 4
  final LatticeShape shape;
  final Color color;
  final Color doneColor;
  final Color errorColor;
  final double cellSize;
  final double gap;
  final double fontSize;
  final int step; // ms
  final double idleOpacity;
  final bool glow;
  final Color? glowColor;
  final bool showTimer;
  final double? elapsed; // Controlled elapsed seconds

  const LatticeLoader({
    super.key,
    this.label = 'Thinking',
    this.doneLabel = 'Done in',
    this.errorLabel = 'Failed after',
    this.status = LatticeStatus.working,
    this.pattern = 'orbit',
    this.grid = 3,
    this.shape = LatticeShape.round,
    this.color = const Color(0xFF00E5FF),
    this.doneColor = const Color(0xFF22C55E),
    this.errorColor = const Color(0xFFEF4444),
    this.cellSize = 6.0,
    this.gap = 2.0,
    this.fontSize = 14.0,
    this.step = 90,
    this.idleOpacity = 0.15,
    this.glow = false,
    this.glowColor,
    this.showTimer = true,
    this.elapsed,
  });

  @override
  State<LatticeLoader> createState() => _LatticeLoaderState();
}

class _LatticeLoaderState extends State<LatticeLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  Timer? _stopwatchTimer;
  int _elapsedDeciseconds = 0;
  DateTime? _startTime;

  // React Bits PATTERNS specifications
  static const Map<String, Map<int, LatticePatternData>> _patterns = {
    'arrow': {
      3: LatticePatternData(
        cells: [1, 2, 3, 0, 1, 2, 1, 2, 3],
        loop: 7.2,
        scale: 1.0,
      ),
    },
    'dots': {
      3: LatticePatternData(
        cells: [0, 1, 2, 0, 1, 2, 0, 1, 2],
        loop: 3.0,
        scale: 2.4,
      ),
    },
    'ripple': {
      3: LatticePatternData(
        cells: [2, 1, 2, 1, 0, 1, 2, 1, 2],
        loop: 4.8,
        scale: 1.5,
      ),
    },
    'spiral': {
      3: LatticePatternData(
        cells: [0, 1, 2, 7, 8, 3, 6, 5, 4],
        loop: 9.0,
        scale: 1.2,
        lit: 0.35,
      ),
    },
    'orbit': {
      3: LatticePatternData(
        cells: [0, 1, 2, 7, null, 3, 6, 5, 4],
        loop: 8.0,
        scale: 1.2,
      ),
      4: LatticePatternData(
        cells: [
          0, 1, 2, 3,
          11, null, null, 4,
          10, null, null, 5,
          9, 8, 7, 6
        ],
        loop: 6.0,
        scale: 1.2,
        lit: 0.45,
      ),
    },
    'snake': {
      3: LatticePatternData(
        cells: [0, 1, 2, 5, 4, 3, 6, 7, 8],
        loop: 9.0,
        scale: 1.0,
        lit: 0.35,
      ),
      4: LatticePatternData(
        cells: [
          0, 1, 2, 3,
          7, 6, 5, 4,
          8, 9, 10, 11,
          15, 14, 13, 12
        ],
        loop: 16.0,
        scale: 1.0,
        lit: 0.25,
      ),
    },
    'sweep': {
      4: LatticePatternData(
        cells: [
          0, 1, 2, 3,
          1, 2, 3, 4,
          2, 3, 4, 5,
          3, 4, 5, 6
        ],
        loop: 5.0,
        scale: 1.0,
        lit: 0.45,
      ),
    },
    'spin': {
      4: LatticePatternData(
        cells: [
          0, 0, 1, 1,
          0, 0, 1, 1,
          3, 3, 2, 2,
          3, 3, 2, 2
        ],
        loop: 4.0,
        scale: 1.6,
        lit: 0.35,
      ),
    },
    'rain': {
      4: LatticePatternData(
        cells: [
          0, 2, 1, 3,
          1, 3, 2, 4,
          2, 4, 3, 5,
          3, 5, 4, 6
        ],
        loop: 4.0,
        scale: 1.2,
        lit: 0.35,
      ),
    },
    'pulse': {
      4: LatticePatternData(
        cells: [
          2, 1, 1, 2,
          1, 0, 0, 1,
          1, 0, 0, 1,
          2, 1, 1, 2
        ],
        loop: 2.4,
        scale: 2.5,
        lit: 0.45,
      ),
    },
  };

  // React Bits MARKS specifications
  static const Map<int, Map<LatticeStatus, List<int>>> _marks = {
    3: {
      LatticeStatus.done: [2, 3, 5, 7], // checkmark
      LatticeStatus.error: [0, 2, 4, 6, 8], // cross
    },
    4: {
      LatticeStatus.done: [7, 8, 10, 13], // checkmark
      LatticeStatus.error: [0, 3, 5, 6, 9, 10, 12, 15], // cross
    },
  };

  LatticePatternData _resolvePattern() {
    final n = widget.grid == 4 ? 4 : 3;
    final map = _patterns[widget.pattern];
    if (map != null && map.containsKey(n)) {
      return map[n]!;
    }
    // Fallback default
    final defaultPattern = n == 4 ? 'sweep' : 'orbit';
    return _patterns[defaultPattern]![n]!;
  }

  int get _cycleMs {
    final pat = _resolvePattern();
    final d = widget.step * pat.scale;
    return (pat.loop * d).round();
  }

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _cycleMs),
    )..repeat();

    _initStopwatch();
  }

  void _initStopwatch() {
    if (widget.elapsed != null) {
      _elapsedDeciseconds = (widget.elapsed! * 10).round();
      return;
    }

    if (widget.status == LatticeStatus.working) {
      _startTime = DateTime.now();
      _elapsedDeciseconds = 0;
      _stopwatchTimer?.cancel();
      _stopwatchTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (_startTime != null && mounted) {
          final diff = DateTime.now().difference(_startTime!);
          setState(() {
            _elapsedDeciseconds = (diff.inMilliseconds / 100).floor();
          });
        }
      });
    } else {
      _stopwatchTimer?.cancel();
    }
  }

  @override
  void didUpdateWidget(covariant LatticeLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pattern != widget.pattern ||
        oldWidget.grid != widget.grid ||
        oldWidget.step != widget.step) {
      _animCtrl.duration = Duration(milliseconds: _cycleMs);
      if (!_animCtrl.isAnimating && widget.status == LatticeStatus.working) {
        _animCtrl.repeat();
      }
    }

    if (oldWidget.status != widget.status) {
      if (widget.status == LatticeStatus.working) {
        _animCtrl.repeat();
        _initStopwatch();
      } else {
        _animCtrl.stop();
        _stopwatchTimer?.cancel();
      }
    }

    if (widget.elapsed != null && widget.elapsed != oldWidget.elapsed) {
      _elapsedDeciseconds = (widget.elapsed! * 10).round();
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _stopwatchTimer?.cancel();
    super.dispose();
  }

  String _formatTimer(int ds) {
    if (ds < 600) {
      return '${(ds / 10).toStringAsFixed(1)}s';
    } else {
      final mins = ds ~/ 600;
      final secs = ((ds % 600) / 10).toStringAsFixed(1);
      return '${mins}m ${secs}s';
    }
  }

  double _calculateCellOpacity(int? unit, double progress, LatticePatternData pat) {
    if (unit == null) {
      return widget.idleOpacity * 0.47;
    }

    final d = widget.step * pat.scale;
    final delayMs = (unit * d).round();
    final totalCycle = _cycleMs;

    final progressMs = (progress * totalCycle).round();
    final localTimeMs = (progressMs - delayMs) % totalCycle;
    final phase = (localTimeMs < 0 ? localTimeMs + totalCycle : localTimeMs) / totalCycle;

    // React Bits Keyframe timings
    // 0%: idle -> 18%..42%: peak -> 62%: idle
    double peakStart = 0.18;
    double peakEnd = 0.42;
    double returnTime = 0.62;

    if ((pat.lit - 0.45).abs() < 0.02) {
      peakStart = 0.13;
      peakEnd = 0.31;
      returnTime = 0.45;
    } else if ((pat.lit - 0.35).abs() < 0.02) {
      peakStart = 0.10;
      peakEnd = 0.24;
      returnTime = 0.35;
    } else if ((pat.lit - 0.25).abs() < 0.02) {
      peakStart = 0.07;
      peakEnd = 0.17;
      returnTime = 0.25;
    }

    if (phase < peakStart) {
      final t = phase / peakStart;
      return widget.idleOpacity + (1.0 - widget.idleOpacity) * Curves.easeInOut.transform(t);
    } else if (phase <= peakEnd) {
      return 1.0;
    } else if (phase < returnTime) {
      final t = (phase - peakEnd) / (returnTime - peakEnd);
      return 1.0 - (1.0 - widget.idleOpacity) * Curves.easeInOut.transform(t);
    } else {
      return widget.idleOpacity;
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.grid == 4 ? 4 : 3;
    final pat = _resolvePattern();
    final markList = _marks[n]?[widget.status] ?? [];
    final activeColor = widget.status == LatticeStatus.error
        ? widget.errorColor
        : (widget.status == LatticeStatus.done ? widget.doneColor : widget.color);

    String labelText;
    switch (widget.status) {
      case LatticeStatus.working:
        labelText = widget.label;
        break;
      case LatticeStatus.done:
        labelText = widget.doneLabel;
        break;
      case LatticeStatus.error:
        labelText = widget.errorLabel;
        break;
    }

    final effectiveGlowColor = widget.glowColor ?? activeColor;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── The Lattice Grid ──────────────────────────────────────────────
        SizedBox(
          width: n * widget.cellSize + (n - 1) * widget.gap,
          height: n * widget.cellSize + (n - 1) * widget.gap,
          child: AnimatedBuilder(
            animation: _animCtrl,
            builder: (context, _) {
              return GridView.builder(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: n,
                  crossAxisSpacing: widget.gap,
                  mainAxisSpacing: widget.gap,
                ),
                itemCount: n * n,
                itemBuilder: (context, index) {
                  final isMark = widget.status != LatticeStatus.working &&
                      markList.contains(index);

                  final double opacity;
                  final Color cellColor;
                  final bool hasGlow;

                  if (widget.status == LatticeStatus.working) {
                    final unit = index < pat.cells.length ? pat.cells[index] : 0;
                    opacity = _calculateCellOpacity(unit, _animCtrl.value, pat);
                    cellColor = widget.color;
                    hasGlow = widget.glow && unit != null && opacity > 0.5;
                  } else {
                    opacity = isMark ? 1.0 : widget.idleOpacity;
                    cellColor = isMark ? activeColor : widget.color;
                    hasGlow = widget.glow && isMark;
                  }

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: cellColor.withValues(alpha: opacity),
                      shape: widget.shape == LatticeShape.round
                          ? BoxShape.circle
                          : BoxShape.rectangle,
                      borderRadius: widget.shape == LatticeShape.square
                          ? BorderRadius.circular(
                              (widget.cellSize * 0.25).clamp(1.0, 4.0))
                          : null,
                      boxShadow: hasGlow
                          ? [
                              BoxShadow(
                                color: effectiveGlowColor.withValues(
                                    alpha: opacity * 0.7),
                                blurRadius: widget.cellSize * 1.2,
                                spreadRadius: widget.cellSize * 0.12,
                              ),
                            ]
                          : null,
                    ),
                  );
                },
              );
            },
          ),
        ),

        SizedBox(width: widget.fontSize * 0.625),

        // ── Label Text (Animated cross-fade) ──────────────────────────────
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            labelText,
            key: ValueKey(labelText),
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: widget.fontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // ── Live Stopwatch Timer ──────────────────────────────────────────
        if (widget.showTimer) ...[
          const SizedBox(width: 8),
          Text(
            _formatTimer(_elapsedDeciseconds),
            style: GoogleFonts.firaCode(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: widget.fontSize * 0.875,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
