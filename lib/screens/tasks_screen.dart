// lib/screens/tasks_screen.dart
//
// 09. Tasks — Real-time task tracking
// Pixel-to-pixel reproduction of reference image:
// Header, title & subtitle, segmented filter pills [All] [Running] [Completed],
// 5 canonical task rows (green checkmark or purple spinner, title, status+time, chevron),
// clickable task inspector sheet, and bottom navigation bar with active Tasks tab.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/tasks_provider.dart';
import '../models/task_model.dart';
import '../services/tasks/jack_task_service.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_nav_bar.dart';

// Real live task tracking for Jack Mobile Agent

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
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '$m ${m == 1 ? "min" : "min"} ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h ${h == 1 ? "hour" : "hours"} ago';
    }
    final d = diff.inDays;
    return '$d ${d == 1 ? "day" : "days"} ago';
  }

  // ── Task detail inspector (bottom modal sheet) ────────────────────────────
  void _showTaskDetails({
    required String title,
    required bool isDone,
    required String statusLabel,
    required String result,
  }) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF100E22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          18,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
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
            const SizedBox(height: 20),

            // Status + Title row
            Row(
              children: [
                // Status indicator (matches reference: green circle or purple spinner)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? const Color(0xFF22C55E).withValues(alpha: 0.15)
                        : const Color(0xFF7C3AED).withValues(alpha: 0.15),
                    border: Border.all(
                      color: isDone
                          ? const Color(0xFF22C55E).withValues(alpha: 0.6)
                          : const Color(0xFF7C3AED).withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                  ),
                  child: isDone
                      ? const Icon(Icons.check_rounded,
                          color: Color(0xFF22C55E), size: 20)
                      : const SizedBox(
                          width: 18,
                          height: 18,
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF7C3AED)),
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        statusLabel,
                        style: GoogleFonts.inter(
                          color: isDone
                              ? const Color(0xFF22C55E)
                              : const Color(0xFFA78BFA),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(color: Colors.white10),
            const SizedBox(height: 12),

            // Result preview
            Text(
              'Jack\'s Result',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF141320),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Text(
                result.isNotEmpty
                    ? result
                    : 'Jack is still working on this task...',
                style: GoogleFonts.inter(
                  color: result.isNotEmpty ? Colors.white : Colors.white38,
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(ctx);
                      context.push('/chat',
                          extra: 'Show more details about: $title');
                    },
                    icon: const Icon(Icons.chat_bubble_outline_rounded,
                        size: 16),
                    label: Text('Discuss in Chat',
                        style:
                            GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Re-running: $title...'),
                          backgroundColor: AppColors.surfaceElevated,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.replay_rounded, size: 16),
                    label: Text('Run Again',
                        style:
                            GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF38BDF8),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Task row matching the reference image exactly ─────────────────────────
  Widget _buildTaskRow({
    required String title,
    required bool isDone,
    required String statusLabel,
    required String result,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          children: [
            // Status indicator: Green filled checkmark circle or purple spinner
            SizedBox(
              width: 30,
              height: 30,
              child: isDone
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF22C55E),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    )
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                        border: Border.all(
                          color: const Color(0xFF7C3AED),
                          width: 1.5,
                        ),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF7C3AED)),
                          ),
                        ),
                      ),
                    ),
            ),

            const SizedBox(width: 14),

            // Title + status label (left side)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    statusLabel,
                    style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            // Trailing chevron
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white24,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                border: Border.all(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: Color(0xFF00E5FF),
                size: 30,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No Tasks Found',
              style: GoogleFonts.cormorantGaramond(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Jack is ready. Give Jack an autonomous goal from Home or Chat to track live progress here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white54,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF141320),
                foregroundColor: const Color(0xFF00E5FF),
                elevation: 0,
                side: BorderSide(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text(
                'Ask Jack',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFromBackend(List<TaskModel> tasks) {
    final filtered = tasks.where((t) {
      final isDone = t.status.toUpperCase() == 'COMPLETED';
      if (_selectedFilter == 1) return !isDone;
      if (_selectedFilter == 2) return isDone;
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          'No ${_filters[_selectedFilter]} tasks',
          style:
              GoogleFonts.inter(color: Colors.white38, fontSize: 13),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      itemCount: filtered.length,
      separatorBuilder: (context, index) => const Divider(
        color: Colors.white10,
        height: 1,
        indent: 44,
      ),
      itemBuilder: (context, index) {
        final task = filtered[index];
        final isDone = task.status.toUpperCase() == 'COMPLETED';
        final statusLabel =
            isDone ? 'Completed • ${_formatTimeAgo(task.updatedAt)}' : 'In progress • ${_formatTimeAgo(task.updatedAt)}';
        return _buildTaskRow(
          title: task.title,
          isDone: isDone,
          statusLabel: statusLabel,
          result: task.result ?? '',
          onTap: () => _showTaskDetails(
            title: task.title,
            isDone: isDone,
            statusLabel: statusLabel,
            result: task.result ?? '',
          ),
        );
      },
    );
  }

  Widget _buildFromJackTasks(List<JackTaskItem> tasks) {
    final filtered = tasks.where((t) {
      if (_selectedFilter == 1) return !t.isDone; // Running
      if (_selectedFilter == 2) return t.isDone; // Completed
      return true; // All
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          'No ${_filters[_selectedFilter]} tasks',
          style: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      itemCount: filtered.length,
      separatorBuilder: (context, index) => const Divider(
        color: Colors.white10,
        height: 1,
        indent: 44,
      ),
      itemBuilder: (context, index) {
        final task = filtered[index];
        return _buildTaskRow(
          title: task.title,
          isDone: task.isDone,
          statusLabel: task.statusLabel,
          result: task.resultSummary ?? task.description,
          onTap: () => _showTaskDetails(
            title: task.title,
            isDone: task.isDone,
            statusLabel: task.statusLabel,
            result: task.resultSummary ?? task.description,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncTasks = ref.watch(tasksProvider);
    final liveTasks = ref.watch(jackTaskProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF07070A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: Colors.white38, size: 20),
            onPressed: () => ref.invalidate(tasksProvider),
            tooltip: 'Refresh tasks',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),

            // ── Header: Title & Subtitle matching Screen 09 ───────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tasks',
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
                    'Track what Jack is working on.',
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

            // ── Filter Pills: [All] [Running] [Completed] ─────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: List.generate(_filters.length, (i) {
                    final active = _selectedFilter == i;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedFilter = i);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: active
                              ? const Color(0xFF38BDF8)
                              : const Color(0xFF141320),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: active
                                ? Colors.transparent
                                : Colors.white.withValues(alpha: 0.08),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _filters[i],
                          style: GoogleFonts.inter(
                            color: active ? Colors.black : Colors.white70,
                            fontSize: 13,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Real task tracking ──────────────────────────────────────────
            Expanded(
              child: liveTasks.isNotEmpty
                  ? _buildFromJackTasks(liveTasks)
                  : asyncTasks.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF00E5FF),
                          strokeWidth: 2,
                        ),
                      ),
                      error: (err, _) => _buildEmptyState(),
                      data: (tasks) => tasks.isEmpty
                          ? _buildEmptyState()
                          : _buildFromBackend(tasks),
                    ),
            ),
          ],
        ),
      ),

      // Bottom Navigation Bar with active Tasks tab
      bottomNavigationBar: GlassNavBar(
        currentIndex: 3, // Tasks is Tab index 3
        onTap: (index) {
          HapticFeedback.lightImpact();
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/tools');
              break;
            case 2:
              context.go('/agent-builder');
              break;
            case 3:
              // Already on Tasks
              break;
            case 4:
              context.go('/profile');
              break;
          }
        },
      ),
    );
  }
}
