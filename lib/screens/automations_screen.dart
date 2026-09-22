// lib/screens/automations_screen.dart
//
// 05. Automations — Create and manage automations
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';

class AutomationsScreen extends StatefulWidget {
  const AutomationsScreen({super.key});

  @override
  State<AutomationsScreen> createState() => _AutomationsScreenState();
}

class _AutomationsScreenState extends State<AutomationsScreen> {
  int _selectedFilter = 0;
  final List<String> _filters = ['All', 'Personal', 'Work', 'Custom'];

  late List<Map<String, dynamic>> _automations;

  @override
  void initState() {
    super.initState();
    _automations = [
      {
        'id': 'auto_1',
        'icon': Icons.wb_sunny_rounded,
        'iconColor': const Color(0xFFFFCC00),
        'title': 'Daily AI Brief',
        'subtitle': 'News, emails, calendar\nEvery morning • 8:00 AM',
        'enabled': true,
        'category': 'Personal',
      },
      {
        'id': 'auto_2',
        'icon': Icons.trending_up_rounded,
        'iconColor': const Color(0xFF00E5FF),
        'title': 'Monitor project',
        'subtitle': 'Track GitHub & send updates\nEvery 6 hours',
        'enabled': true,
        'category': 'Work',
      },
      {
        'id': 'auto_3',
        'icon': Icons.sell_rounded,
        'iconColor': const Color(0xFFFF3377),
        'title': 'Check price drops',
        'subtitle': 'Monitor products & alert me',
        'enabled': true,
        'category': 'Personal',
      },
      {
        'id': 'auto_4',
        'icon': Icons.groups_rounded,
        'iconColor': const Color(0xFF8B5CF6),
        'title': 'Social media helper',
        'subtitle': 'Draft & schedule posts\nWeekdays • 6:00 PM',
        'enabled': false,
        'category': 'Work',
      },
      {
        'id': 'auto_5',
        'icon': Icons.search_rounded,
        'iconColor': const Color(0xFF14B8A6),
        'title': 'Research competitor',
        'subtitle': 'Weekly market research\nEvery Sunday',
        'enabled': true,
        'category': 'Work',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _automations.where((item) {
      if (_selectedFilter == 0) return true;
      final f = _filters[_selectedFilter];
      return item['category'] == f;
    }).toList();

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
                    'Automations',
                    style: GoogleFonts.cormorantGaramond(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Set it once. Jack handles the rest.',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Segmented Filters: [All] [Personal] [Work] [Custom]
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
                        margin: const EdgeInsets.symmetric(horizontal: 3),
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
                              fontSize: 12,
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

            // Automation cards list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final auto = filtered[index];
                  final enabled = auto['enabled'] as bool;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Leading rounded icon container
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF141320),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              auto['icon'] as IconData,
                              color: auto['iconColor'] as Color,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Title and schedule
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  auto['title'] as String,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  auto['subtitle'] as String,
                                  style: GoogleFonts.inter(
                                    color: Colors.white54,
                                    fontSize: 11.5,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Toggle Switch
                          Switch(
                            value: enabled,
                            onChanged: (val) {
                              HapticFeedback.lightImpact();
                              setState(() => auto['enabled'] = val);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    val
                                        ? '${auto['title']} activated'
                                        : '${auto['title']} paused',
                                  ),
                                  backgroundColor: AppColors.surfaceElevated,
                                  duration: const Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            activeTrackColor:
                                AppColors.accentCyan.withValues(alpha: 0.5),
                            activeThumbColor: AppColors.accentCyan,
                            inactiveTrackColor: Colors.white12,
                            inactiveThumbColor: Colors.white38,
                          ),
                        ],
                      ),
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
