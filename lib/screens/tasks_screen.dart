// lib/screens/tasks_screen.dart
//
// 09. Tasks — Real-time task tracking
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../design/jack_components.dart';
import '../providers/tasks_provider.dart';
import '../theme/app_colors.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
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
    final tasksAsync = ref.watch(tasksProvider);
    final List<Map<String, dynamic>> activeList = tasksAsync.maybeWhen(
      data: (backendList) {
        if (backendList.isNotEmpty) {
          return backendList.map((t) {
            final isDone = t.status.toUpperCase() == 'COMPLETED';
            return {
              'id': t.id,
              'title': t.title,
              'subtitle': '${t.status.toLowerCase()} • task id #${t.id.substring(0, t.id.length > 6 ? 6 : t.id.length)}',
              'status': isDone ? 'Completed' : 'Running',
              'isCompleted': isDone,
              'iconColor': isDone ? const Color(0xFF00FF88) : const Color(0xFF9B2BFF),
            };
          }).toList();
        }
        return _tasks;
      },
      orElse: () => _tasks,
    );

    final filtered = activeList.where((t) {
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
                    child: JackTaskCard(
                      title: task['title'] as String,
                      subtitle: task['subtitle'] as String,
                      isCompleted: isDone,
                      iconColor: iconColor,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.push('/chat', extra: 'Details for ${task['title']}');
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
