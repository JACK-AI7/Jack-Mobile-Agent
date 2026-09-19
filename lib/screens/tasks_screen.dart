// lib/screens/tasks_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tasks_provider.dart';
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

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
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
    final tasksAsync = ref.watch(tasksProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilters(),
            Expanded(
              child: tasksAsync.when(
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return const Center(child: Text('No tasks found.', style: TextStyle(color: Colors.white54)));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final t = tasks[index];
                      return GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.action, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text('Status: ', style: const TextStyle(color: Colors.white54)),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accentCyan)),
                error: (e, st) => Center(child: Text('Error: ', style: const TextStyle(color: Colors.red))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Tasks',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildFilterChip('All', TaskFilter.all),
          const SizedBox(width: 8),
          _buildFilterChip('Running', TaskFilter.running),
          const SizedBox(width: 8),
          _buildFilterChip('Completed', TaskFilter.completed),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, TaskFilter filter) {
    final isActive = _activeFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.white : Colors.white12,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.black : Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
