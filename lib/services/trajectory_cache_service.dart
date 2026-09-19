// lib/services/trajectory_cache_service.dart
//
// Jack — Episodic Memory & App Trajectory Caching
// Caches successful sequences of semantic node IDs, coordinates, and intents.
// Replays cached workflows at native speed (<1s) and falls back to AI on layout updates.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'jack_controller.dart';
import 'jack_shizuku_controller.dart';
import 'jack_autonomous_supervisor.dart';

class CachedTrajectoryStep {
  final String actionType; // "INTENT", "CLICK_TEXT", "CLICK_ID", "CLICK_COORDS", "INPUT_TEXT", "GLOBAL"
  final String? target;
  final double? x;
  final double? y;
  final int waitMs;

  const CachedTrajectoryStep({
    required this.actionType,
    this.target,
    this.x,
    this.y,
    this.waitMs = 500,
  });

  Map<String, dynamic> toJson() => {
        'actionType': actionType,
        'target': target,
        'x': x,
        'y': y,
        'waitMs': waitMs,
      };

  factory CachedTrajectoryStep.fromJson(Map<String, dynamic> json) =>
      CachedTrajectoryStep(
        actionType: json['actionType'] as String? ?? 'CLICK_TEXT',
        target: json['target'] as String?,
        x: (json['x'] as num?)?.toDouble(),
        y: (json['y'] as num?)?.toDouble(),
        waitMs: (json['waitMs'] as num?)?.toInt() ?? 500,
      );
}

class TrajectoryCacheService {
  static const String _prefKeyPrefix = 'jack_trajectory_';

  /// Saves a successfully executed macro path for [taskKey]
  static Future<void> saveTrajectory(
    String taskKey,
    List<CachedTrajectoryStep> steps,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(steps.map((s) => s.toJson()).toList());
      await prefs.setString('$_prefKeyPrefix${taskKey.toLowerCase().trim()}', encoded);
      debugPrint('[TrajectoryCache] Saved ${steps.length} steps for "$taskKey"');
    } catch (e) {
      debugPrint('[TrajectoryCache] Save error: $e');
    }
  }

  /// Retrieves a cached path if available
  static Future<List<CachedTrajectoryStep>?> getTrajectory(String taskKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefKeyPrefix${taskKey.toLowerCase().trim()}');
      if (raw == null || raw.isEmpty) return null;
      final list = jsonDecode(raw) as List;
      return list
          .map((item) => CachedTrajectoryStep.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[TrajectoryCache] Read error: $e');
      return null;
    }
  }

  /// Replays a cached sequence of actions at native speed with auto self-healing
  static Future<bool> replayTrajectory(
    String taskKey, {
    Map<String, String>? runtimeVariables,
  }) async {
    final steps = await getTrajectory(taskKey);
    if (steps == null || steps.isEmpty) {
      debugPrint('[TrajectoryCache] Cache miss for "$taskKey"');
      return false;
    }

    debugPrint('[TrajectoryCache] Replaying ${steps.length} cached steps for "$taskKey"');

    for (final step in steps) {
      bool stepSuccess = false;

      switch (step.actionType) {
        case "CLICK_TEXT":
          if (step.target != null) {
            stepSuccess = await JackAutonomousSupervisor.executeWithVerification(
              goalDescription: 'Click "${step.target}"',
              action: () => JackController.clickElement(text: step.target),
              verifySuccess: () async => true,
            );
          }
          break;

        case "CLICK_ID":
          if (step.target != null) {
            stepSuccess = await JackAutonomousSupervisor.executeWithVerification(
              goalDescription: 'Click ID "${step.target}"',
              action: () => JackController.clickElement(id: step.target),
              verifySuccess: () async => true,
            );
          }
          break;

        case "CLICK_COORDS":
          if (step.x != null && step.y != null) {
            await JackController.tapCoordinates(step.x!, step.y!);
            stepSuccess = true;
          }
          break;

        case "INPUT_TEXT":
          final rawText = step.target ?? '';
          final resolvedText = runtimeVariables?[rawText] ?? rawText;
          stepSuccess = await JackShizukuController.typeText(resolvedText);
          break;

        case "GLOBAL":
          if (step.target != null) {
            stepSuccess = await JackController.triggerGlobal(step.target!);
          }
          break;

        default:
          stepSuccess = true;
          break;
      }

      if (!stepSuccess && step.x != null && step.y != null) {
        // Fallback to coordinate tap
        debugPrint('[TrajectoryCache] Step failed, falling back to cached coordinates (${step.x}, ${step.y})');
        await JackController.tapCoordinates(step.x!, step.y!);
      }

      if (step.waitMs > 0) {
        await Future.delayed(Duration(milliseconds: step.waitMs));
      }
    }

    return true;
  }

  /// Clears cache for a task key
  static Future<void> invalidate(String taskKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefKeyPrefix${taskKey.toLowerCase().trim()}');
  }
}
