// lib/widgets/system_telemetry_strip.dart
//
// Jack — System Telemetry Strip
// Horizontal tabular panel · Monospace figures · 1px glass dividers
// 6px glow micro-indicator dots · BATTERY / AUDIO / TORCH / AGENT CORE
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/jack_design_tokens.dart';
import '../models/agent_models.dart';

class SystemTelemetryStrip extends StatelessWidget {
  final AgentState agent;
  final VoidCallback? onBatteryTap;
  final VoidCallback? onAudioTap;
  final VoidCallback? onTorchTap;

  const SystemTelemetryStrip({
    super.key,
    required this.agent,
    this.onBatteryTap,
    this.onAudioTap,
    this.onTorchTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SpecularBorderPainter(radius: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
            decoration: BoxDecoration(
              color: JackDesignTokens.glassSurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _TelemetryCell(
                    label: 'BATTERY',
                    value: '88%',
                    dotColor: JackDesignTokens.siriEmerald,
                    icon: Icons.battery_charging_full_rounded,
                    onTap: onBatteryTap,
                  ),
                  const _GlassDivider(),
                  _TelemetryCell(
                    label: 'AUDIO',
                    value: 'NORM',
                    dotColor: JackDesignTokens.siriCyan,
                    icon: Icons.volume_up_rounded,
                    onTap: onAudioTap,
                  ),
                  const _GlassDivider(),
                  _TelemetryCell(
                    label: 'TORCH',
                    value: 'STBY',
                    dotColor: JackDesignTokens.siriAmber,
                    icon: Icons.flashlight_on_rounded,
                    onTap: onTorchTap,
                  ),
                  const _GlassDivider(),
                  _TelemetryCell(
                    label: 'AGENT CORE',
                    value: _agentCoreValue(agent.status),
                    dotColor: _agentCoreDot(agent.status),
                    icon: Icons.memory_rounded,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _agentCoreValue(AgentStatus s) {
    switch (s) {
      case AgentStatus.listening:  return 'LISTEN';
      case AgentStatus.thinking:   return 'THINK';
      case AgentStatus.executingOS: return 'EXEC';
      case AgentStatus.complete:   return 'DONE';
      default: return 'READY';
    }
  }

  Color _agentCoreDot(AgentStatus s) {
    switch (s) {
      case AgentStatus.listening:  return JackDesignTokens.siriCyan;
      case AgentStatus.thinking:   return JackDesignTokens.siriPurple;
      case AgentStatus.executingOS: return JackDesignTokens.siriAmber;
      case AgentStatus.complete:   return JackDesignTokens.siriEmerald;
      default: return const Color(0x60FFFFFF);
    }
  }
}

class _TelemetryCell extends StatelessWidget {
  final String label;
  final String value;
  final Color dotColor;
  final IconData icon;
  final VoidCallback? onTap;

  const _TelemetryCell({
    required this.label,
    required this.value,
    required this.dotColor,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glow micro-dot
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(bottom: 5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor,
                boxShadow: [
                  BoxShadow(
                    color: dotColor,
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            Icon(icon, color: dotColor, size: 16),
            const SizedBox(height: 4),
            Text(value, style: JackDesignTokens.telemetryValue),
            const SizedBox(height: 2),
            Text(label, style: JackDesignTokens.telemetryLabel),
          ],
        ),
      ),
    );
  }
}

class _GlassDivider extends StatelessWidget {
  const _GlassDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: 0.18),
            Colors.white.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}

class _SpecularBorderPainter extends CustomPainter {
  final double radius;
  _SpecularBorderPainter({required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x55FFFFFF),
          Color(0x15FFFFFF),
          Color(0x04FFFFFF),
        ],
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_SpecularBorderPainter o) => false;
}
