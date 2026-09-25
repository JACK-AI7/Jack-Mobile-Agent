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
    JackTaskRecorder.activeNotifier = this;
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
      }
    } catch (_) {}

    if (state.isEmpty) {
      state = [
        JackTaskItem(
          id: 'task_init',
          title: 'Jack Mobile Agent Online',
          description: 'Accessibility DOM, Telephony, and Hardware engines active.',
          status: JackTaskStatus.completed,
          createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
          completedAt: DateTime.now().subtract(const Duration(minutes: 2)),
          resultSummary: 'System controller connected and ready.',
          category: 'System',
        ),
      ];
      _saveTasks();
    }
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

  Future<void> updateTaskItem(String id, JackTaskItem Function(JackTaskItem) updater) async {
    state = [
      for (final t in state)
        if (t.id == id) updater(t) else t,
    ];
    await _saveTasks();
  }

  Future<void> removeTask(String id) async {
    state = state.where((t) => t.id != id).toList();
    await _saveTasks();
  }

  JackTaskItem? getTaskById(String id) {
    try {
      return state.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}

final jackTaskProvider =
    StateNotifierProvider<JackTaskNotifier, List<JackTaskItem>>((ref) {
  return JackTaskNotifier();
});

class JackTaskRecorder {
  static JackTaskNotifier? activeNotifier;
  static String? _activeSessionTaskId;
  static int _sessionActionCount = 0;

  static Future<String> startOrGetSessionTask({String? initialTitle}) async {
    if (_activeSessionTaskId != null) {
      return _activeSessionTaskId!;
    }
    _sessionActionCount = 0;
    final id = 'task_${DateTime.now().millisecondsSinceEpoch}';
    _activeSessionTaskId = id;
    final item = JackTaskItem(
      id: id,
      title: initialTitle ?? 'Jack Live Voice Session',
      description: 'Active continuous live voice session outside the app.',
      status: JackTaskStatus.inProgress,
      createdAt: DateTime.now(),
      category: 'Voice Assistant',
      resultSummary: 'Listening for voice commands...',
    );

    if (activeNotifier != null) {
      await activeNotifier!.addTask(item);
    } else {
      try {
        final raw = await JackStorage.read(key: JackTaskNotifier._storageKey);
        List<dynamic> list = [];
        if (raw != null && raw.isNotEmpty) {
          list = jsonDecode(raw) as List<dynamic>;
        }
        list.insert(0, item.toJson());
        await JackStorage.write(
            key: JackTaskNotifier._storageKey, value: jsonEncode(list));
      } catch (_) {}
    }
    return id;
  }

  static Future<void> appendSessionAction(String command, String result) async {
    final id = await startOrGetSessionTask(initialTitle: 'Live: $command');
    _sessionActionCount++;
    if (activeNotifier != null) {
      final current = activeNotifier!.getTaskById(id) ??
          JackTaskItem(
            id: id,
            title: 'Live: $command',
            description: '',
            status: JackTaskStatus.inProgress,
            createdAt: DateTime.now(),
          );
      final newDesc = current.description.contains('•')
          ? '${current.description}\n• $command -> $result'
          : '• $command -> $result';
      await activeNotifier!.updateTaskItem(id, (t) => t.copyWith(
            title: current.title == 'Jack Live Voice Session' ? 'Live: $command' : current.title,
            description: newDesc,
            status: JackTaskStatus.inProgress,
            resultSummary: 'Completed $_sessionActionCount actions. Last: $command',
          ));
    } else {
      try {
        final raw = await JackStorage.read(key: JackTaskNotifier._storageKey);
        if (raw != null && raw.isNotEmpty) {
          final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
          final idx = list.indexWhere((item) => item['id'] == id);
          if (idx != -1) {
            final old = list[idx] as Map<String, dynamic>;
            final oldDesc = old['description']?.toString() ?? '';
            final newDesc = oldDesc.contains('•') ? '$oldDesc\n• $command -> $result' : '• $command -> $result';
            old['description'] = newDesc;
            old['resultSummary'] = 'Completed $_sessionActionCount actions. Last: $command';
            await JackStorage.write(
                key: JackTaskNotifier._storageKey, value: jsonEncode(list));
          }
        }
      } catch (_) {}
    }
  }

  static Future<void> completeSessionTask() async {
    if (_activeSessionTaskId == null) return;
    final id = _activeSessionTaskId!;
    _activeSessionTaskId = null;
    final summary = 'Live session completed successfully ($_sessionActionCount actions executed).';
    if (activeNotifier != null) {
      await activeNotifier!.updateTaskStatus(id, JackTaskStatus.completed, result: summary);
    } else {
      try {
        final raw = await JackStorage.read(key: JackTaskNotifier._storageKey);
        if (raw != null && raw.isNotEmpty) {
          final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
          final idx = list.indexWhere((item) => item['id'] == id);
          if (idx != -1) {
            final old = list[idx] as Map<String, dynamic>;
            old['status'] = 'completed';
            old['completedAt'] = DateTime.now().toIso8601String();
            old['resultSummary'] = summary;
            await JackStorage.write(
                key: JackTaskNotifier._storageKey, value: jsonEncode(list));
          }
        }
      } catch (_) {}
    }
    _sessionActionCount = 0;
  }

  static Future<void> recordTask({
    required String title,
    required String description,
    required String category,
    JackTaskStatus status = JackTaskStatus.completed,
    String? resultSummary,
  }) async {
    final item = JackTaskItem(
      id: 'task_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      status: status,
      createdAt: DateTime.now(),
      completedAt: status == JackTaskStatus.completed ? DateTime.now() : null,
      resultSummary: resultSummary,
      category: category,
    );

    if (activeNotifier != null) {
      await activeNotifier!.addTask(item);
    } else {
      try {
        final raw = await JackStorage.read(key: JackTaskNotifier._storageKey);
        List<dynamic> list = [];
        if (raw != null && raw.isNotEmpty) {
          list = jsonDecode(raw) as List<dynamic>;
        }
        list.insert(0, item.toJson());
        await JackStorage.write(
            key: JackTaskNotifier._storageKey, value: jsonEncode(list));
      } catch (_) {}
    }
  }
}
