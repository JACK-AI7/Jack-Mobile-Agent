// lib/widgets/grok_think_card.dart
//
// Jack — Grok "Think Mode" Expandable Accordion Widget
// Exposes inner monologue, self-correction, and planning traces with frosted glass styling.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

class GrokThinkCard extends StatefulWidget {
  final String thoughtTrace;
  final Widget child;
  final String? durationLabel;

  const GrokThinkCard({
    super.key,
    required this.thoughtTrace,
    required this.child,
    this.durationLabel,
  });

  @override
  State<GrokThinkCard> createState() => _GrokThinkCardState();
}

class _GrokThinkCardState extends State<GrokThinkCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.thoughtTrace.trim().isEmpty) {
      return widget.child;
    }

    final duration = widget.durationLabel ?? "Thought for 0.6s...";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Collapsible Thinking Accordion Header
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isExpanded
                      ? Icons.psychology_alt_rounded
                      : Icons.lightbulb_outline_rounded,
                  color: const Color(0xFF00F0FF),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  _isExpanded ? "Hide Thought Process" : duration,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 16,
                ),
              ],
            ),
          ),
        ),

        // Expanded Transparent Thought Trace
        if (_isExpanded)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF080B14).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFF00F0FF).withValues(alpha: 0.25),
              ),
            ),
            child: Text(
              widget.thoughtTrace,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 13,
                fontFamily: 'monospace',
                height: 1.45,
              ),
            ),
          ),

        // Main Result / Card
        widget.child,
      ],
    );
  }
}
