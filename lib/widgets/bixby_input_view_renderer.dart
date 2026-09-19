// lib/widgets/bixby_input_view_renderer.dart
//
// Jack — Bixby Input View Renderer
// Mounts interactive choices whenever an action returns AWAITING_INPUT
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'real_glass_card.dart';

class BixbyInputViewRenderer extends StatelessWidget {
  final Map<String, dynamic> viewPayload;
  final Function(Map<String, dynamic> selectedPayload) onOptionSelected;
  final VoidCallback onCancelled;

  const BixbyInputViewRenderer({
    super.key,
    required this.viewPayload,
    required this.onOptionSelected,
    required this.onCancelled,
  });

  @override
  Widget build(BuildContext context) {
    final renderData = viewPayload['render'] as Map<String, dynamic>? ?? {};
    final elements = renderData['elements'] as List? ?? [];
    final drivers = viewPayload['conversation_drivers'] as List? ?? [];

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 400),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Selection Card Container
          RealGlassCard(
            borderRadius: 24,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "SELECT OPTION",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                ...elements.map((elem) => _buildSelectableItem(elem)),
              ],
            ),
          ),

          // Contextual Drivers / Cancel Action
          if (drivers.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: drivers.map((driver) {
                return ActionChip(
                  backgroundColor: const Color(0x18FFFFFF),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  label: Text(
                    driver['template'] ?? 'Cancel',
                    style: const TextStyle(color: Color(0xFFFF2D55), fontSize: 12),
                  ),
                  onPressed: onCancelled,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectableItem(Map<String, dynamic> item) {
    final title = item['slot2']?['title'] ?? '';
    final subtitle = item['slot2']?['subtitle'] ?? '';
    final payload = item['payload'] as Map<String, dynamic>? ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onOptionSelected(payload),
          splashColor: const Color(0xFF00F0FF).withValues(alpha: 0.15),
          highlightColor: Colors.white.withValues(alpha: 0.05),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                  child: Text(
                    item['slot1']?['text'] ?? '•',
                    style: const TextStyle(color: Color(0xFF00F0FF), fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      if (subtitle.isNotEmpty)
                        Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withValues(alpha: 0.3), size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
