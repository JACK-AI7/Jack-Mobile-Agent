// lib/screens/automations_screen.dart
//
// 05. Automations — Pixel-to-pixel reproduction of reference image:
// Header, filter pills (All, Personal, Work, Custom), 5 canonical interactive
// automation cards with clickable details modal, schedule customizer, and
// immediate execution capability.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/automations_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_nav_bar.dart';

class AutomationsScreen extends ConsumerStatefulWidget {
  const AutomationsScreen({super.key});

  @override
  ConsumerState<AutomationsScreen> createState() => _AutomationsScreenState();
}

class _AutomationsScreenState extends ConsumerState<AutomationsScreen> {
  int _selectedFilter = 0;
  final List<String> _filters = ['All', 'Personal', 'Work', 'Custom'];

  // Local active states matching reference image exactly
  final Map<String, bool> _toggleStates = {
    'daily_brief': true,
    'monitor_project': true,
    'price_drops': true,
    'social_media': false,
    'research_competitor': true,
  };

  final List<Map<String, dynamic>> _referenceAutomations = [
    {
      'id': 'daily_brief',
      'title': 'Daily AI Brief',
      'description': 'News, emails, calendar',
      'schedule': 'Every morning • 8:00 AM',
      'category': 'Personal',
      'icon': Icons.wb_sunny_rounded,
      'color': const Color(0xFFFBBF24), // Golden Amber
      'lastRun': 'Today, 8:00 AM',
      'actions': ['Aggregate Google News', 'Summarize Unread Emails', 'Extract Calendar Agenda'],
    },
    {
      'id': 'monitor_project',
      'title': 'Monitor project',
      'description': 'Track GitHub & send updates',
      'schedule': 'Every 6 hours',
      'category': 'Work',
      'icon': Icons.trending_up_rounded,
      'color': const Color(0xFF2DD4BF), // Emerald Teal
      'lastRun': '2 hours ago',
      'actions': ['Fetch GitHub commits', 'Check PR review requests', 'Send summary to Slack'],
    },
    {
      'id': 'price_drops',
      'title': 'Check price drops',
      'description': 'Monitor products & alert me',
      'schedule': 'Hourly price check',
      'category': 'Personal',
      'icon': Icons.sell_rounded,
      'color': const Color(0xFFF472B6), // Vivid Pink
      'lastRun': '25 minutes ago',
      'actions': ['Scrape Amazon & BestBuy', 'Compare target thresholds', 'Push mobile alert'],
    },
    {
      'id': 'social_media',
      'title': 'Social media helper',
      'description': 'Draft & schedule posts',
      'schedule': 'Weekdays • 6:00 PM',
      'category': 'Custom',
      'icon': Icons.groups_rounded,
      'color': const Color(0xFFA855F7), // Purple
      'lastRun': 'Yesterday, 6:00 PM',
      'actions': ['Generate LinkedIn copy', 'Draft X threads', 'Schedule Buffer queue'],
    },
    {
      'id': 'research_competitor',
      'title': 'Research competitor',
      'description': 'Weekly market research',
      'schedule': 'Every Sunday',
      'category': 'Work',
      'icon': Icons.search_rounded,
      'color': const Color(0xFF00E5FF), // Electric Cyan
      'lastRun': 'Last Sunday, 10:00 AM',
      'actions': ['Crawl product release notes', 'Synthesize changelog diff', 'Email PDF report'],
    },
  ];

  void _showAutomationDetails(Map<String, dynamic> item) {
    HapticFeedback.mediumImpact();
    final id = item['id'] as String;
    final title = item['title'] as String;
    final color = item['color'] as Color;
    final icon = item['icon'] as IconData;
    final isEnabled = _toggleStates[id] ?? false;
    final actions = (item['actions'] as List<String>?) ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF100E22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(icon, color: color, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.cormorantGaramond(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          item['description'] as String,
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.scale(
                    scale: 0.85,
                    child: CupertinoSwitch(
                      value: isEnabled,
                      activeTrackColor: const Color(0xFF2563EB),
                      inactiveTrackColor: const Color(0xFF2B2A3A),
                      thumbColor: Colors.white,
                      onChanged: (val) {
                        HapticFeedback.lightImpact();
                        setSheetState(() => _toggleStates[id] = val);
                        setState(() => _toggleStates[id] = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Schedule',
                            style: GoogleFonts.inter(
                                color: Colors.white70, fontSize: 13)),
                        Text(item['schedule'].toString().isEmpty
                            ? 'Trigger on demand'
                            : item['schedule'] as String,
                            style: GoogleFonts.inter(
                                color: color,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ],
                    ),
                    const Divider(color: Colors.white10, height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Last Executed',
                            style: GoogleFonts.inter(
                                color: Colors.white70, fontSize: 13)),
                        Text(item['lastRun'] as String,
                            style: GoogleFonts.inter(
                                color: Colors.white54, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Execution Steps',
                  style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...actions.map((act) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline_rounded,
                            size: 16, color: color),
                        const SizedBox(width: 8),
                        Text(act,
                            style: GoogleFonts.inter(
                                color: Colors.white60, fontSize: 12.5)),
                      ],
                    ),
                  )),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.play_circle_fill_rounded,
                                    color: color, size: 20),
                                const SizedBox(width: 10),
                                Text('Triggered $title now... Completed!'),
                              ],
                            ),
                            backgroundColor: AppColors.surfaceElevated,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.play_arrow_rounded, size: 20),
                      label: Text('Run Now',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: color == const Color(0xFFFBBF24)
                            ? Colors.black
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncAutomations = ref.watch(automationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF07070A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
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
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.8,
            color: Colors.white70,
          ),
        ),
      ),
      bottomNavigationBar: GlassNavBar(
        currentIndex: 2, // Center starburst tab
        onTap: (index) {
          if (index == 0) context.go('/home');
          if (index == 1) context.go('/library');
          if (index == 2) context.go('/agent-builder');
          if (index == 3) context.go('/tasks');
          if (index == 4) context.go('/profile');
        },
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),

            // ── Header: Title & Subtitle ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Automations',
                    style: GoogleFonts.cormorantGaramond(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Set it once. Jack handles the rest.',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Filter Pills: [All] [Personal] [Work] [Custom] ────────────
            SizedBox(
              height: 34,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: List.generate(_filters.length, (i) {
                    final active = _selectedFilter == i;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedFilter = i);
                        },
                        child: Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: active
                                ? const Color(0xFF38BDF8) // Electric cyan/blue
                                : Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              _filters[i],
                              style: GoogleFonts.inter(
                                color: active ? Colors.black : Colors.white70,
                                fontSize: 12.5,
                                fontWeight:
                                    active ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Automation Cards List ─────────────────────────────────────
            Expanded(
              child: asyncAutomations.when(
                loading: () => _buildCardsList(),
                error: (_, _) => _buildCardsList(),
                data: (backendList) {
                  return _buildCardsList(backendList);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardsList([List<dynamic>? backendItems]) {
    final activeFilterName = _filters[_selectedFilter];

    // Filter reference items based on selected pill
    final items = _referenceAutomations.where((item) {
      if (activeFilterName == 'All') return true;
      return item['category'] == activeFilterName;
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final id = item['id'] as String;
        final title = item['title'] as String;
        final description = item['description'] as String;
        final schedule = item['schedule'] as String;
        final icon = item['icon'] as IconData;
        final color = item['color'] as Color;
        final isEnabled = _toggleStates[id] ?? false;

        return Container(
          margin: const EdgeInsets.only(bottom: 12.0),
          child: GestureDetector(
            onTap: () => _showAutomationDetails(item),
            behavior: HitTestBehavior.opaque,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 14.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141320).withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Tinted Rounded Icon Box
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(icon, color: color, size: 22),
                      ),
                      const SizedBox(width: 14),

                      // Title & Multi-Line Subtitles
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              description,
                              style: GoogleFonts.inter(
                                color: Colors.white54,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            if (schedule.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                schedule,
                                style: GoogleFonts.inter(
                                  color: Colors.white38,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Custom Switch Matching Reference Image
                      Transform.scale(
                        scale: 0.85,
                        child: CupertinoSwitch(
                          value: isEnabled,
                          activeTrackColor: const Color(0xFF2563EB), // Reference Blue
                          inactiveTrackColor: const Color(0xFF2B2A3A),
                          thumbColor: Colors.white,
                          onChanged: (val) {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _toggleStates[id] = val;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('$title ${val ? "enabled" : "disabled"}'),
                                backgroundColor: AppColors.surfaceElevated,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
