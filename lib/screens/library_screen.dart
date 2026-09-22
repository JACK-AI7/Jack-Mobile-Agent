// lib/screens/library_screen.dart
//
// 08. Library — Saved agents, prompts & workflows
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../design/jack_components.dart';
import '../theme/app_colors.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int _selectedFilter = 0;
  final List<String> _filters = ['Agents', 'Prompts', 'Workflows'];

  late List<Map<String, dynamic>> _items;

  @override
  void initState() {
    super.initState();
    _items = [
      {
        'id': 'agent_1',
        'title': 'Research Agent',
        'subtitle': 'Deep research & analysis',
        'icon': Icons.explore_rounded,
        'iconColor': const Color(0xFF2B6BFF),
        'type': 'Agents',
      },
      {
        'id': 'agent_2',
        'title': 'Content Agent',
        'subtitle': 'Create & edit content',
        'icon': Icons.edit_note_rounded,
        'iconColor': const Color(0xFF00E5FF),
        'type': 'Agents',
      },
      {
        'id': 'agent_3',
        'title': 'Data Analyst',
        'subtitle': 'Analyze data & generate insights',
        'icon': Icons.bar_chart_rounded,
        'iconColor': const Color(0xFF3B82F6),
        'type': 'Agents',
      },
      {
        'id': 'agent_4',
        'title': 'Social Media Agent',
        'subtitle': 'Plan & schedule posts',
        'icon': Icons.share_rounded,
        'iconColor': const Color(0xFF8B5CF6),
        'type': 'Agents',
      },
      {
        'id': 'agent_5',
        'title': 'Custom Agent',
        'subtitle': 'Your own agent',
        'icon': Icons.smart_toy_rounded,
        'iconColor': const Color(0xFFA855F7),
        'type': 'Agents',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07070A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/home');
            }
          },
        ),
        centerTitle: true,
        title: Text(
          'JACK AGENT',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 3.0,
            color: Colors.white70,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Library',
                    style: GoogleFonts.cormorantGaramond(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your saved agents, prompts and workflows.',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Segmented Filters: [Agents] [Prompts] [Workflows]
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: List.generate(_filters.length, (i) {
                  final active = _selectedFilter == i;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedFilter = i);
                      },
                      child: Container(
                        height: 34,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.accentCyan
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: Center(
                          child: Text(
                            _filters[i],
                            style: GoogleFonts.inter(
                              color: active ? Colors.black : Colors.white70,
                              fontSize: 12.5,
                              fontWeight: active
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 16),

            // Library items list matching Screen 08
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: JackAgentCard(
                      title: item['title'] as String,
                      subtitle: item['subtitle'] as String,
                      icon: item['icon'] as IconData,
                      iconColor: item['iconColor'] as Color,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.push('/chat', extra: 'Run ${item['title']}');
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
