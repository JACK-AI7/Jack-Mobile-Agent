// lib/screens/tasks_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/glass_card.dart';
import '../widgets/jack_orb.dart';

enum TaskStatus { inProgress, completed }

enum StepStatus { completed, inProgress, pending }

enum TaskFilter { all, running, completed }

class TaskStep {
  final String title;
  final String symbol; // '✓', '●', '○'
  final StepStatus status;

  const TaskStep({
    required this.title,
    required this.symbol,
    required this.status,
  });
}

class TaskItem {
  final String id;
  final String title;
  final TaskStatus status;
  final String timeAgo;
  final IconData icon;
  final Color iconColor;
  final double progress; // 0.0 - 1.0
  final List<TaskStep> steps;

  const TaskItem({
    required this.id,
    required this.title,
    required this.status,
    required this.timeAgo,
    required this.icon,
    required this.iconColor,
    required this.progress,
    required this.steps,
  });
}

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  TaskFilter _activeFilter = TaskFilter.all;
  final Set<String> _expandedTaskIds = {'1'};

  static const List<TaskStep> _defaultSteps = [
    TaskStep(
      title: 'Understanding request',
      symbol: '✓',
      status: StepStatus.completed,
    ),
    TaskStep(
      title: 'Planning',
      symbol: '✓',
      status: StepStatus.completed,
    ),
    TaskStep(
      title: 'Searching',
      symbol: '●',
      status: StepStatus.inProgress,
    ),
    TaskStep(
      title: 'Analyzing',
      symbol: '○',
      status: StepStatus.pending,
    ),
    TaskStep(
      title: 'Preparing answer',
      symbol: '○',
      status: StepStatus.pending,
    ),
  ];

  late final List<TaskItem> _tasks;

  @override
  void initState() {
    super.initState();
    _tasks = const [
      TaskItem(
        id: '1',
        title: 'Laptop research',
        status: TaskStatus.inProgress,
        timeAgo: '2 min ago',
        icon: Icons.laptop_chromebook_rounded,
        iconColor: AppColors.accentCyan,
        progress: 0.60,
        steps: _defaultSteps,
      ),
      TaskItem(
        id: '2',
        title: 'Summarize article',
        status: TaskStatus.completed,
        timeAgo: '1 hour ago',
        icon: Icons.article_rounded,
        iconColor: AppColors.accentViolet,
        progress: 1.0,
        steps: _defaultSteps,
      ),
      TaskItem(
        id: '3',
        title: 'Create presentation',
        status: TaskStatus.completed,
        timeAgo: '3 hours ago',
        icon: Icons.slideshow_rounded,
        iconColor: AppColors.accentPink,
        progress: 1.0,
        steps: _defaultSteps,
      ),
      TaskItem(
        id: '4',
        title: 'Analyze dataset',
        status: TaskStatus.inProgress,
        timeAgo: '5 hours ago',
        icon: Icons.analytics_rounded,
        iconColor: AppColors.accentTeal,
        progress: 0.40,
        steps: _defaultSteps,
      ),
      TaskItem(
        id: '5',
        title: 'Plan vacation',
        status: TaskStatus.completed,
        timeAgo: '1 day ago',
        icon: Icons.flight_takeoff_rounded,
        iconColor: AppColors.accentIndigo,
        progress: 1.0,
        steps: _defaultSteps,
      ),
    ];
  }

  void _toggleTaskExpansion(String taskId) {
    setState(() {
      if (_expandedTaskIds.contains(taskId)) {
        _expandedTaskIds.remove(taskId);
      } else {
        _expandedTaskIds.add(taskId);
      }
    });
  }

  List<TaskItem> get _filteredTasks {
    switch (_activeFilter) {
      case TaskFilter.all:
        return _tasks;
      case TaskFilter.running:
        return _tasks
            .where((task) => task.status == TaskStatus.inProgress)
            .toList();
      case TaskFilter.completed:
        return _tasks
            .where((task) => task.status == TaskStatus.completed)
            .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTasks;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildFilterRow(),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildTaskCard(filtered[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final runningCount =
        _tasks.where((t) => t.status == TaskStatus.inProgress).length;
    final canPop = Navigator.canPop(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (canPop) ...[
            GestureDetector(
              onTap: () => Navigator.maybePop(context),
              child: Container(
                width: 38,
                height: 38,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.surfaceBorder,
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tasks',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 34,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Track what Jack is working on.',
                  style: AppTypography.body(
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          JackOrb(
            size: 46,
            state: runningCount > 0 ? OrbState.working : OrbState.idle,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    final runningCount =
        _tasks.where((t) => t.status == TaskStatus.inProgress).length;
    final completedCount =
        _tasks.where((t) => t.status == TaskStatus.completed).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.surfaceBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildFilterTab(
            key: const Key('filter_all'),
            label: 'All',
            filter: TaskFilter.all,
            count: _tasks.length,
          ),
          _buildFilterTab(
            key: const Key('filter_running'),
            label: 'Running',
            filter: TaskFilter.running,
            count: runningCount,
          ),
          _buildFilterTab(
            key: const Key('filter_completed'),
            label: 'Completed',
            filter: TaskFilter.completed,
            count: completedCount,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab({
    Key? key,
    required String label,
    required TaskFilter filter,
    required int count,
  }) {
    final isSelected = _activeFilter == filter;

    return Expanded(
      child: GestureDetector(
        key: key,
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _activeFilter = filter;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surfaceElevated : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(
                    color: AppColors.accentCyan.withValues(alpha: 0.35),
                    width: 1,
                  )
                : Border.all(
                    color: Colors.transparent,
                    width: 1,
                  ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.accentCyan.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accentCyan.withValues(alpha: 0.18)
                      : AppColors.surfaceBorder.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppColors.accentCyan
                        : AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(TaskItem task) {
    final isExpanded = _expandedTaskIds.contains(task.id);

    return GlassCard(
      onTap: () => _toggleTaskExpansion(task.id),
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      borderColor: isExpanded
          ? AppColors.accentCyan.withValues(alpha: 0.32)
          : AppColors.surfaceBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: task.iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: task.iconColor.withValues(alpha: 0.28),
                    width: 1,
                  ),
                ),
                child: Icon(
                  task.icon,
                  color: task.iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          task.timeAgo,
                          style: AppTypography.caption(
                            size: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusBadge(task.status),
              const SizedBox(width: 6),
              AnimatedRotation(
                turns: isExpanded ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
            ],
          ),
          if (task.status == TaskStatus.inProgress) ...[
            const SizedBox(height: 14),
            _buildProgressBar(task.progress),
          ],
          if (isExpanded) ...[
            const SizedBox(height: 16),
            Divider(
              color: AppColors.surfaceBorder.withValues(alpha: 0.7),
              height: 1,
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'EXECUTION TIMELINE',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textTertiary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    '${task.steps.where((s) => s.status == StepStatus.completed).length}/${task.steps.length} completed',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ...task.steps.asMap().entries.map((entry) {
              final idx = entry.key;
              final step = entry.value;
              return _buildTimelineStep(
                step: step,
                isFirst: idx == 0,
                isLast: idx == task.steps.length - 1,
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(TaskStatus status) {
    final isCompleted = status == TaskStatus.completed;
    final color = isCompleted ? AppColors.success : AppColors.accentCyan;
    final label = isCompleted ? 'Completed' : 'In progress';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.6),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double progress) {
    final percent = (progress * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '$percent%',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.accentCyan,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              height: 6,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceBorder.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  height: 6,
                  width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.accentCyan,
                        AppColors.accentViolet,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentCyan.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTimelineStep({
    required TaskStep step,
    required bool isFirst,
    required bool isLast,
  }) {
    Color nodeColor;
    Widget nodeIcon;

    switch (step.status) {
      case StepStatus.completed:
        nodeColor = AppColors.success;
        nodeIcon = const Icon(
          Icons.check_rounded,
          size: 11,
          color: AppColors.background,
        );
        break;
      case StepStatus.inProgress:
        nodeColor = AppColors.accentCyan;
        nodeIcon = Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: AppColors.accentCyan,
            shape: BoxShape.circle,
          ),
        );
        break;
      case StepStatus.pending:
        nodeColor = AppColors.textTertiary;
        nodeIcon = const SizedBox.shrink();
        break;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: 8,
                  color: isFirst
                      ? Colors.transparent
                      : (step.status == StepStatus.pending
                          ? AppColors.surfaceBorder
                          : AppColors.accentCyan.withValues(alpha: 0.4)),
                ),
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: step.status == StepStatus.completed
                        ? AppColors.success
                        : (step.status == StepStatus.inProgress
                            ? AppColors.accentCyan.withValues(alpha: 0.2)
                            : Colors.transparent),
                    border: Border.all(
                      color: nodeColor,
                      width: step.status == StepStatus.inProgress ? 2 : 1.5,
                    ),
                  ),
                  child: Center(child: nodeIcon),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast
                        ? Colors.transparent
                        : (step.status == StepStatus.pending
                            ? AppColors.surfaceBorder
                            : AppColors.accentCyan.withValues(alpha: 0.4)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${step.title} ${step.symbol}',
                      style: AppTypography.body(
                        size: 13,
                        color: step.status == StepStatus.pending
                            ? AppColors.textTertiary
                            : (step.status == StepStatus.inProgress
                                ? AppColors.accentCyan
                                : AppColors.textPrimary),
                      ).copyWith(
                        fontWeight: step.status == StepStatus.inProgress
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: const Icon(
                Icons.task_alt_rounded,
                size: 30,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks found',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'There are no ${_activeFilter.name} tasks to display.',
              textAlign: TextAlign.center,
              style: AppTypography.caption(
                size: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
