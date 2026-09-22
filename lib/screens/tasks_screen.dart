// lib/screens/tasks_screen.dart
//
// 09. Tasks — Real tasks from backend only. Zero fake data.
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

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
  }

  @override
  Widget build(BuildContext context) {
    final asyncTasks = ref.watch(tasksProvider);

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
        actions: [
          // Pull-to-refresh button
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white54, size: 20),
            onPressed: () => ref.invalidate(tasksProvider),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
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

            // ── Filter tabs: [All] [Running] [Completed]
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

            const SizedBox(height: 16),

            // ── Real task data only
            Expanded(
              child: asyncTasks.when(
                loading: () => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentCyan),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Loading tasks...',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                error: (err, _) => _buildErrorState(
                  err.toString().replaceAll('Exception: ', ''),
                ),
                data: (tasks) {
                  // Apply status filter
                  final filtered = tasks.where((t) {
                    final isDone = t.status.toUpperCase() == 'COMPLETED';
                    if (_selectedFilter == 1) return !isDone; // Running
                    if (_selectedFilter == 2) return isDone;  // Completed
                    return true; // All
                  }).toList();

                  if (tasks.isEmpty) {
                    return _buildEmptyState();
                  }

                  if (filtered.isEmpty) {
                    return _buildEmptyFilterState(_filters[_selectedFilter]);
                  }

                  return ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final task = filtered[index];
                      final isDone = task.status.toUpperCase() == 'COMPLETED';
                      final timeAgo = _formatTimeAgo(task.updatedAt);
                      final statusText =
                          isDone ? 'Completed • $timeAgo' : 'In progress • $timeAgo';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: JackTaskCard(
                          title: task.title,
                          subtitle: statusText,
                          isCompleted: isDone,
                          iconColor: isDone
                              ? const Color(0xFF00FF88)
                              : const Color(0xFF9B2BFF),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            context.push('/chat',
                                extra: task.result != null && task.result!.isNotEmpty
                                    ? 'Task result: ${task.result}'
                                    : 'Show details for task: ${task.title}');
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.white24, size: 48),
            const SizedBox(height: 16),
            Text(
              'Could not load tasks',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message.contains('Authentication')
                  ? 'Please log in again to view your tasks.'
                  : 'Backend is unreachable. Check your connection.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: Colors.white38, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => ref.invalidate(tasksProvider),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                    color: AppColors.accentCyan.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Retry',
                  style: GoogleFonts.inter(color: AppColors.accentCyan)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.task_alt_outlined, color: Colors.white24, size: 48),
            const SizedBox(height: 16),
            Text(
              'No tasks yet',
              style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask Jack to do something on the home screen\nand your tasks will appear here in real time.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: Colors.white38, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.home_rounded, size: 18),
              label: Text('Ask Jack',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentCyan,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFilterState(String filter) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              filter == 'Running'
                  ? Icons.hourglass_empty_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white24,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'No $filter tasks',
              style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              filter == 'Running'
                  ? 'No tasks are currently running.'
                  : 'No completed tasks yet.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: Colors.white38, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
