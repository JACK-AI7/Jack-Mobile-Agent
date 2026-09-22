// lib/screens/tasks_screen.dart
//
// 09. Tasks — Real-time task tracking
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  int _selectedFilter = 0;
  final List<String> _filters = ['All', 'Running', 'Completed'];

  late List<Map<String, dynamic>> _tasks;

  @override
  void initState() {
    super.initState();
    _tasks = [
      {
        'id': 'task_1',
        'title': 'Laptop research',
        'subtitle': 'In progress • 2 min ago',
        'status': 'Running',
        'isCompleted': false,
        'iconColor': const Color(0xFF00FF88),
      },
      {
        'id': 'task_2',
        'title': 'Summarize article',
        'subtitle': 'Completed • 1 hour ago',
        'status': 'Completed',
        'isCompleted': true,
        'iconColor': const Color(0xFF00FF88),
      },
      {
        'id': 'task_3',
        'title': 'Create presentation',
        'subtitle': 'Completed • 3 hours ago',
        'status': 'Completed',
        'isCompleted': true,
        'iconColor': const Color(0xFF00FF88),
      },
      {
        'id': 'task_4',
        'title': 'Analyze dataset',
        'subtitle': 'In progress • 5 hours ago',
        'status': 'Running',
        'isCompleted': false,
        'iconColor': const Color(0xFF9B2BFF),
      },
      {
        'id': 'task_5',
        'title': 'Plan vacation',
        'subtitle': 'Completed • 1 day ago',
        'status': 'Completed',
        'isCompleted': true,
        'iconColor': const Color(0xFF00E5FF),
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _tasks.where((t) {
      if (_selectedFilter == 1) return t['status'] == 'Running';
      if (_selectedFilter == 2) return t['status'] == 'Completed';
      return true;
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
                    'Tasks',
                    style: GoogleFonts.cormorantGaramond(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track what Jack is working on.',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Segmented Filters: [All] [Running] [Completed]
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

            // Task list matching Screen 09
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final task = filtered[index];
                  final isDone = task['isCompleted'] as bool;
                  final iconColor = task['iconColor'] as Color;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.push('/chat', extra: 'Details for ${task['title']}');
                      },
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            // Leading Status Icon
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: iconColor.withValues(alpha: 0.15),
                              ),
                              child: Icon(
                                isDone
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_checked_rounded,
                                color: iconColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Task Title & Subtitle
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task['title'] as String,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    task['subtitle'] as String,
                                    style: GoogleFonts.inter(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Trailing Chevron
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white30,
                              size: 20,
                            ),
                          ],
                        ),
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
