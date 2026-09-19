// lib/widgets/grok_roast_card.dart
//
// Jack — Grok "Roast Capsule" Glass Card Widget
// Renders witty, unhinged system audits, spicy burns, and quick conversation drivers.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import '../theme/siri_gemini_theme.dart';
import '../theme/jack_design_tokens.dart';
import 'real_glass_card.dart';


class GrokRoastCard extends StatelessWidget {
  final String title;
  final String? headline;
  final String content;
  final List<Map<String, String>> drivers;
  final ValueChanged<String>? onQuerySelected;

  const GrokRoastCard({
    super.key,
    required this.title,
    this.headline,
    required this.content,
    this.drivers = const [],
    this.onQuerySelected,
  });

  factory GrokRoastCard.fromJson(
    Map<String, dynamic> json, {
    ValueChanged<String>? onQuerySelected,
  }) {
    final rawDrivers = json['conversation_drivers'] as List? ?? [];
    final driversList = <Map<String, String>>[];
    for (final d in rawDrivers) {
      if (d is Map) {
        driversList.add({
          'label': d['label']?.toString() ?? '',
          'query': d['query']?.toString() ?? '',
        });
      }
    }

    return GrokRoastCard(
      title: json['title']?.toString() ?? 'Grok Roast',
      headline: json['headline']?.toString(),
      content: json['content']?.toString() ?? '',
      drivers: driversList,
      onQuerySelected: onQuerySelected,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RealGlassCard(
      tintColor: JackDesignTokens.siriMagenta,
      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Flame icon + Roast Mode Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: SiriGeminiTheme.siriMagenta.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: SiriGeminiTheme.siriMagenta,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: SiriGeminiTheme.siriMagenta.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: SiriGeminiTheme.siriMagenta.withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: const Text(
                  'ROAST',
                  style: TextStyle(
                    color: SiriGeminiTheme.siriMagenta,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),

          // Optional Headline
          if (headline != null && headline!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              headline!,
              style: TextStyle(
                color: SiriGeminiTheme.siriAmber,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],

          // Roast Content Body
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.45,
            ),
          ),

          // Conversation Drivers / Quick Reply Chips
          if (drivers.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: drivers.map((driver) {
                final label = driver['label'] ?? '';
                final query = driver['query'] ?? label;
                return GestureDetector(
                  onTap: () => onQuerySelected?.call(query),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: SiriGeminiTheme.siriPurple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: SiriGeminiTheme.siriPurple.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.bolt_rounded,
                          color: SiriGeminiTheme.siriPurple,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
