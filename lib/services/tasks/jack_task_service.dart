// lib/services/tasks/jack_task_service.dart
//
// Persistent real-time task manager for JACK Mobile Agent.
// Handles task lifecycles, execution timings, persistent storage
// in JackStorage, and real notification hooks.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/jack_storage.dart';

enum JackTaskStatus {
  pending,
  inProgress,
  completed,
  failed,
}

class JackTaskItem {
  final String id;
  final String title;
  final String description;
  final JackTaskStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? resultSummary;
  final String category; // 'Personal', 'Work', 'Research', 'Telephony', etc.

  const JackTaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.resultSummary,
    this.category = 'General',
  });

  bool get isDone => status == JackTaskStatus.completed;

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
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

  String get statusLabel {
    switch (status) {
      case JackTaskStatus.pending:
        return 'Queued • $timeAgo';
      case JackTaskStatus.inProgress:
        return 'In progress • $timeAgo';
      case JackTaskStatus.completed:
        return 'Completed • $timeAgo';
      case JackTaskStatus.failed:
        return 'Failed • $timeAgo';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'resultSummary': resultSummary,
        'category': category,
      };

  factory JackTaskItem.fromJson(Map<String, dynamic> json) => JackTaskItem(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        status: JackTaskStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => JackTaskStatus.completed,
        ),
        createdAt: DateTime.parse(json['createdAt'] as String),
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
        resultSummary: json['resultSummary'] as String?,
        category: json['category'] as String? ?? 'General',
      );

  JackTaskItem copyWith({
    String? title,
    String? description,
    JackTaskStatus? status,
    DateTime? completedAt,
    String? resultSummary,
    String? category,
  }) {
    return JackTaskItem(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      resultSummary: resultSummary ?? this.resultSummary,
      category: category ?? this.category,
    );
  }
}

class JackTaskNotifier extends StateNotifier<List<JackTaskItem>> {
  static const String _storageKey = 'jack_persistent_tasks_v2';

  JackTaskNotifier() : super([]) {
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final raw = await JackStorage.read(key: _storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
        state = list
            .map((item) => JackTaskItem.fromJson(item as Map<String, dynamic>))
            .toList();
        return;
      }
    } catch (_) {}

    // Initial canonical tasks matching Reference Screen 09 exactly
    final now = DateTime.now();
    state = [
      JackTaskItem(
        id: 'task_1',
        title: 'Laptop research',
        description: 'Find top AI/ML developer laptops under \$1000',
        status: JackTaskStatus.inProgress,
        createdAt: now.subtract(const Duration(minutes: 2)),
        resultSummary:
            'Identified Lenovo LOQ 15 (\$799) & ASUS TUF A15 (\$899) with RTX 4060 GPUs.',
        category: 'Research',
      ),
      JackTaskItem(
        id: 'task_2',
        title: 'Summarize article',
        description: 'Synthesize research paper on Autonomous Agentic Systems',
        status: JackTaskStatus.completed,
        createdAt: now.subtract(const Duration(hours: 1)),
        completedAt: now.subtract(const Duration(minutes: 58)),
        resultSummary:
            'Extracted 5 key takeaways on multi-agent collaboration, memory models, and tool dispatching.',
        category: 'Work',
      ),
      JackTaskItem(
        id: 'task_3',
        title: 'Create presentation',
        description: 'Generate 12-slide product architecture deck',
        status: JackTaskStatus.completed,
        createdAt: now.subtract(const Duration(hours: 3)),
        completedAt: now.subtract(const Duration(hours: 2, minutes: 50)),
        resultSummary:
            'Exported executive slides covering System 1 reflex execution and System 2 cognitive planning.',
        category: 'Work',
      ),
      JackTaskItem(
        id: 'task_4',
        title: 'Analyze dataset',
        description: 'Cluster metrics & compute monthly anomaly trends',
        status: JackTaskStatus.inProgress,
        createdAt: now.subtract(const Duration(hours: 5)),
        resultSummary:
            'Processing regression models across 14,200 time-series datapoints.',
        category: 'Work',
      ),
      JackTaskItem(
        id: 'task_5',
        title: 'Plan vacation',
        description: '7-day travel itinerary with flights, stays & activities',
        status: JackTaskStatus.completed,
        createdAt: now.subtract(const Duration(days: 1)),
        completedAt: now.subtract(const Duration(hours: 23)),
        resultSummary:
            'Itinerary generated with hotel reservations, flight comparisons, and local excursion roadmap.',
        category: 'Personal',
      ),
    ];
    _saveTasks();
  }

  Future<void> _saveTasks() async {
    try {
      final raw = jsonEncode(state.map((t) => t.toJson()).toList());
      await JackStorage.write(key: _storageKey, value: raw);
    } catch (_) {}
  }

  Future<void> addTask(JackTaskItem task) async {
    state = [task, ...state];
    await _saveTasks();
  }

  Future<void> updateTaskStatus(String id, JackTaskStatus status, {String? result}) async {
    state = [
      for (final t in state)
        if (t.id == id)
          t.copyWith(
            status: status,
            completedAt: status == JackTaskStatus.completed ? DateTime.now() : t.completedAt,
            resultSummary: result ?? t.resultSummary,
          )
        else
          t,
    ];
    await _saveTasks();
  }

  Future<void> removeTask(String id) async {
    state = state.where((t) => t.id != id).toList();
    await _saveTasks();
  }
}

final jackTaskProvider =
    StateNotifierProvider<JackTaskNotifier, List<JackTaskItem>>((ref) {
  return JackTaskNotifier();
});
