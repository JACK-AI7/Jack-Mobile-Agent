// lib/screens/tasks_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/task_model.dart';
import '../providers/tasks_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';

// ── Filter enum ────────────────────────────────────────────────────────────────

enum TaskFilter { all, running, completed }

// ── Status helpers ─────────────────────────────────────────────────────────────

/// Returns the display label for a raw status string.
String _statusLabel(String status) {
  switch (status.toUpperCase()) {
    case 'COMPLETED':
      return 'Completed';
    case 'RUNNING':
      return 'Running';
    case 'PLANNING':
      return 'Planning';
    case 'QUEUED':
      return 'Queued';
    case 'FAILED':
      return 'Failed';
    case 'CANCELLED':
      return 'Cancelled';
    default:
      return status;
  }
}

/// Returns the badge colour for a given raw status string.
Color _statusColor(String status) {
  switch (status.toUpperCase()) {
    case 'COMPLETED':
      return AppColors.success;
    case 'RUNNING':
    case 'PLANNING':
    case 'QUEUED':
      return AppColors.accentCyan;
    case 'FAILED':
      return AppColors.error;
    case 'CANCELLED':
      return Colors.grey;
    default:
      return AppColors.textSecondary;
  }
}

/// Returns the icon for a given raw status string.
IconData _statusIcon(String status) {
  switch (status.toUpperCase()) {
    case 'COMPLETED':
      return Icons.check_circle_outline_rounded;
    case 'RUNNING':
      return Icons.sync_rounded;
    case 'PLANNING':
      return Icons.lightbulb_outline_rounded;
    case 'QUEUED':
      return Icons.schedule_rounded;
    case 'FAILED':
      return Icons.error_outline_rounded;
    case 'CANCELLED':
      return Icons.cancel_outlined;
    default:
      return Icons.help_outline_rounded;
  }
}

/// Returns true when a status belongs to the "running" filter bucket.
bool _isRunning(String status) {
  switch (status.toUpperCase()) {
    case 'RUNNING':
    case 'PLANNING':
    case 'QUEUED':
      return true;
    default:
      return false;
  }
}

/// Returns true when a status belongs to the "completed" filter bucket.
bool _isTerminal(String status) {
  switch (status.toUpperCase()) {
    case 'COMPLETED':
    case 'FAILED':
    case 'CANCELLED':
      return true;
    default:
      return false;
  }
}

// ── Time-ago helper ────────────────────────────────────────────────────────────

String _timeAgo(DateTime utcTime) {
  final now = DateTime.now().toUtc();
  final diff = now.difference(utcTime.toUtc());

  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    return '$m min ago';
  }
  if (diff.inHours < 24) {
    final h = diff.inHours;
    return '$h hr ago';
  }
  if (diff.inDays < 7) {
    final d = diff.inDays;
    return '$d day${d == 1 ? '' : 's'} ago';
  }
  final local = utcTime.toLocal();
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[local.month - 1]} ${local.day}';
}

// ── Screen ─────────────────────────────────────────────────────────────────────

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  TaskFilter _filter = TaskFilter.all;

  // ── Filter logic ──────────────────────────────────────────────────────────

  List<TaskModel> _applyFilter(List<TaskModel> tasks) {
    switch (_filter) {
      case TaskFilter.all:
        return tasks;
      case TaskFilter.running:
        return tasks.where((t) => _isRunning(t.status)).toList();
      case TaskFilter.completed:
        return tasks.where((t) => _isTerminal(t.status)).toList();
    }
  }

  // ── Pull-to-refresh ───────────────────────────────────────────────────────

  Future<void> _refresh() async {
    ref.invalidate(tasksProvider);
    await ref.read(tasksProvider.future).catchError((_) {});
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSegmentedControl(),
            Expanded(
              child: tasksAsync.when(
                data: (tasks) {
                  final filtered = _applyFilter(tasks);
                  return RefreshIndicator(
                    color: AppColors.accentCyan,
                    backgroundColor: AppColors.surfaceCard,
                    onRefresh: _refresh,
                    child: filtered.isEmpty
                        ? _buildEmptyState()
                        : _buildTaskList(filtered),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.accentCyan,
                    strokeWidth: 2,
                  ),
                ),
                error: (e, _) => _buildErrorState(e),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tasks',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Track what Jack is working on',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            color: AppColors.textSecondary,
            splashRadius: 20,
            onPressed: _refresh,
          ),
        ],
      ),
    );
  }

  // ── Segmented control ─────────────────────────────────────────────────────

  Widget _buildSegmentedControl() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.surfaceBorder, width: 1),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            _buildTab('All', TaskFilter.all),
            _buildTab('Running', TaskFilter.running),
            _buildTab('Completed', TaskFilter.completed),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, TaskFilter filter) {
    final isActive = _filter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filter = filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.accentCyan.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: isActive
                ? Border.all(
                    color: AppColors.accentCyan.withValues(alpha: 0.35),
                    width: 1,
                  )
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? AppColors.accentCyan : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  // ── Task list ─────────────────────────────────────────────────────────────

  Widget _buildTaskList(List<TaskModel> tasks) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildTaskCard(tasks[index]),
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    final color = _statusColor(task.status);
    final icon = _statusIcon(task.status);
    final label = _statusLabel(task.status);
    final timeStr = _timeAgo(task.createdAt);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status icon circle
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.30),
                width: 1.2,
              ),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row: action + badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        task.action,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(label: label, color: color),
                  ],
                ),
                // Result preview
                if (task.result != null && task.result!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    task.result!.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
                // Time row
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 11,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeStr,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    final message = switch (_filter) {
      TaskFilter.all => 'No tasks yet.\nAsk Jack to do something.',
      TaskFilter.running => 'No active tasks right now.',
      TaskFilter.completed => 'No completed tasks yet.',
    };

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.52,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.surfaceBorder,
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.task_alt_rounded,
                    color: AppColors.textTertiary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Error state ───────────────────────────────────────────────────────────

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.error,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              'Failed to load tasks',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: TextButton.styleFrom(foregroundColor: AppColors.accentCyan),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status badge widget ────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
