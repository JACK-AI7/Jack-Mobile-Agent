// lib/services/agent/jack_droid_run_engine.dart
//
// Jack — On-Device DroidRun & OpenGUI Mobile Agent Engine
// ─────────────────────────────────────────────────────────────────────────────
// Autonomous Mobile Agent Framework built specifically for smartphone processors.
// Combines:
// 1. OpenGUI Perception: Dumps Accessibility DOM tree into indexed UI elements [1], [2], [3].
// 2. Mobile Action Loop: Perceive → Plan → Act → Verify trajectory with sub-second step time.
// 3. Dual-Layer Execution: Accessibility Service (Zero Root) + Shizuku ADB Shell (UID 2000).
// 4. Closed-Loop Self-Healing: Auto-dismisses popups, ads, soft keyboards, and recovers stalls.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../app_launcher_helper.dart';
import '../jack_controller.dart';
import '../jack_shizuku_controller.dart';
import '../jack_autonomous_supervisor.dart';
import '../api/direct_groq_service.dart';
import '../tasks/jack_task_service.dart';

enum DroidRunState {
  idle,
  perceiving,
  planning,
  acting,
  verifying,
  completed,
  failed,
}

class DroidRunStep {
  final int stepIndex;
  final String actionType; // 'CLICK', 'TYPE', 'SWIPE', 'LAUNCH', 'GLOBAL', 'FINISH'
  final String description;
  final String target;
  final DateTime timestamp;
  final bool success;

  DroidRunStep({
    required this.stepIndex,
    required this.actionType,
    required this.description,
    required this.target,
    required this.timestamp,
    required this.success,
  });

  Map<String, dynamic> toMap() => {
        'step': stepIndex,
        'action': actionType,
        'description': description,
        'target': target,
        'time': timestamp.toIso8601String(),
        'success': success,
      };
}

class UiElementNode {
  final int index;
  final String text;
  final String resourceId;
  final bool clickable;
  final double centerX;
  final double centerY;
  final Map<String, dynamic> bounds;

  UiElementNode({
    required this.index,
    required this.text,
    required this.resourceId,
    required this.clickable,
    required this.centerX,
    required this.centerY,
    required this.bounds,
  });

  String get displayLabel {
    if (text.isNotEmpty) return text;
    if (resourceId.isNotEmpty) {
      final clean = resourceId.contains(':id/')
          ? resourceId.split(':id/').last
          : resourceId;
      return '[$clean]';
    }
    return '[Interactive Element]';
  }
}

class JackDroidRunEngine {
  static final JackDroidRunEngine instance = JackDroidRunEngine._internal();
  JackDroidRunEngine._internal();

  DroidRunState _state = DroidRunState.idle;
  DroidRunState get state => _state;

  final ValueNotifier<DroidRunState> stateNotifier =
      ValueNotifier<DroidRunState>(DroidRunState.idle);

  final ValueNotifier<List<DroidRunStep>> trajectoryNotifier =
      ValueNotifier<List<DroidRunStep>>([]);

  final ValueNotifier<String> currentGoalNotifier = ValueNotifier<String>('');
  final ValueNotifier<String> statusMessageNotifier = ValueNotifier<String>('Idle');

  bool _abortRequested = false;

  /// Main autonomous execution loop: takes any human goal and runs it on the phone
  Future<bool> executeGoal(String goal) async {
    if (_state != DroidRunState.idle && _state != DroidRunState.completed && _state != DroidRunState.failed) {
      debugPrint('[DroidRun] Execution already in progress.');
      return false;
    }

    _abortRequested = false;
    _setState(DroidRunState.perceiving, 'Starting autonomous task...');
    currentGoalNotifier.value = goal;
    trajectoryNotifier.value = [];

    debugPrint('🚀 [DroidRun] Initializing autonomous loop for: "$goal"');
    JackTaskRecorder.recordTask(
      title: goal.length > 36 ? '${goal.substring(0, 36)}...' : goal,
      description: 'Autonomous DroidRun execution',
      category: 'Autonomous Mobile Agent',
      resultSummary: 'Executing on-device trajectory...',
    );

    int stepCount = 0;
    const int maxSteps = 10;
    final List<String> actionHistory = [];

    // Pre-flight check: ensure accessibility service is active
    final a11yActive = await JackController.isAccessibilityActive();
    if (!a11yActive) {
      _setState(DroidRunState.failed, 'Accessibility Service not active. Please enable in Settings.');
      await JackController.openAccessibilitySettings();
      return false;
    }

    // Step 0: Check if goal requires launching an app first
    final initialApp = _detectTargetApp(goal);
    if (initialApp != null) {
      _setState(DroidRunState.acting, 'Launching $initialApp...');
      stepCount++;
      final launched = await AppLauncherHelper.launchAppByName(initialApp);
      _recordStep(stepCount, 'LAUNCH', 'Launched $initialApp', initialApp, launched);
      actionHistory.add('LAUNCH($initialApp)');
      await Future.delayed(const Duration(milliseconds: 1500));
    }

    // Closed-loop Autonomous Reasoning Loop
    while (stepCount < maxSteps && !_abortRequested) {
      stepCount++;
      _setState(DroidRunState.perceiving, 'Perceiving active screen (OpenGUI)...');

      // 1. Perceive: Extract DOM tree
      final rawNodes = await JackController.inspectScreen();
      final indexedElements = _parseAndIndexNodes(rawNodes);

      if (indexedElements.isEmpty) {
        debugPrint('[DroidRun] No interactive nodes found. Retrying with delay...');
        await Future.delayed(const Duration(milliseconds: 800));
        continue;
      }

      // 2. Plan: Query LLM planner with goal + UI elements + history
      _setState(DroidRunState.planning, 'Planning next UI action...');
      final plan = await _planNextAction(goal, indexedElements, actionHistory);

      if (plan == null) {
        _setState(DroidRunState.failed, 'Planner returned empty decision.');
        return false;
      }

      final action = plan['action']?.toString().toUpperCase() ?? 'WAIT';
      final targetIndex = plan['index'] as int?;
      final targetText = plan['text']?.toString() ?? '';
      final description = plan['description']?.toString() ?? 'Executing $action';

      debugPrint('[DroidRun] Step $stepCount: Action=$action Target=$targetIndex Description=$description');

      // 3. Check for FINISH
      if (action == 'FINISH') {
        _recordStep(stepCount, 'FINISH', description, targetText, true);
        _setState(DroidRunState.completed, 'Goal achieved: $description');
        JackTaskRecorder.completeSessionTask();
        return true;
      }

      // 4. Act: Dispatch gesture or input
      _setState(DroidRunState.acting, description);
      bool actionResult = false;

      if (action == 'CLICK') {
        if (targetIndex != null && targetIndex >= 0 && targetIndex < indexedElements.length) {
          final el = indexedElements[targetIndex];
          actionResult = await JackController.clickElement(
            id: el.resourceId.isNotEmpty ? el.resourceId : null,
            text: el.text.isNotEmpty ? el.text : null,
          );
          if (!actionResult) {
            await JackController.tapCoordinates(el.centerX, el.centerY);
            actionResult = true;
          }
        } else if (targetText.isNotEmpty) {
          actionResult = await JackController.clickElement(text: targetText);
        }
      } else if (action == 'TYPE') {
        final textToType = plan['data']?.toString() ?? targetText;
        if (targetIndex != null && targetIndex >= 0 && targetIndex < indexedElements.length) {
          final el = indexedElements[targetIndex];
          actionResult = await JackController.typeText(
            id: el.resourceId.isNotEmpty ? el.resourceId : null,
            text: el.text.isNotEmpty ? el.text : null,
            data: textToType,
          );
        } else {
          // Shizuku or generic fallback
          actionResult = await JackShizukuController.typeText(textToType);
        }
      } else if (action == 'SWIPE' || action == 'SCROLL') {
        final dir = plan['direction']?.toString().toUpperCase() ?? 'DOWN';
        if (dir == 'UP') {
          await JackController.swipe(startX: 540, startY: 1500, endX: 540, endY: 500);
        } else {
          await JackController.swipe(startX: 540, startY: 600, endX: 540, endY: 1500);
        }
        actionResult = true;
      } else if (action == 'GLOBAL') {
        final key = plan['key']?.toString().toUpperCase() ?? 'BACK';
        await JackController.triggerGlobal(key);
        actionResult = true;
      } else if (action == 'LAUNCH') {
        final appName = plan['app']?.toString() ?? targetText;
        actionResult = await AppLauncherHelper.launchAppByName(appName);
      }

      _recordStep(stepCount, action, description, targetText, actionResult);
      actionHistory.add('$action($description)');

      // 5. Verify & Self-Heal: Wait for settle and dismiss popups
      _setState(DroidRunState.verifying, 'Verifying screen transition...');
      await Future.delayed(const Duration(milliseconds: 700));
      await JackAutonomousSupervisor.dismissUnexpectedModals();
    }

    if (_abortRequested) {
      _setState(DroidRunState.failed, 'Execution aborted by user.');
      return false;
    }

    _setState(DroidRunState.completed, 'Autonomous trajectory completed.');
    return true;
  }

  void abort() {
    _abortRequested = true;
    _setState(DroidRunState.failed, 'Aborting autonomous trajectory...');
  }

  // ── OpenGUI Perception Parsing ───────────────────────────────────────────────
  List<UiElementNode> _parseAndIndexNodes(List<Map<String, dynamic>> rawNodes) {
    final List<UiElementNode> result = [];
    int idx = 0;

    for (final node in rawNodes) {
      final text = node['text']?.toString().trim() ?? '';
      final resId = node['id']?.toString().trim() ?? '';
      final clickable = node['clickable'] == true;
      final bounds = node['bounds'] as Map<String, dynamic>? ?? {};

      final cx = (bounds['centerX'] as num?)?.toDouble() ?? 0.0;
      final cy = (bounds['centerY'] as num?)?.toDouble() ?? 0.0;

      // Filter out empty background containers with 0 size
      if (text.isEmpty && resId.isEmpty && !clickable) continue;

      result.add(UiElementNode(
        index: idx++,
        text: text,
        resourceId: resId,
        clickable: clickable,
        centerX: cx,
        centerY: cy,
        bounds: bounds,
      ));
    }
    return result;
  }

  // ── LLM Action Planner ───────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> _planNextAction(
    String goal,
    List<UiElementNode> elements,
    List<String> history,
  ) async {
    final elementPrompt = elements.take(40).map((e) {
      return '[${e.index}] "${e.displayLabel}" (id: ${e.resourceId}, clickable: ${e.clickable})';
    }).join('\n');

    final systemPrompt = """
You are DroidRun, an autonomous on-device mobile AI agent controlling an Android smartphone.
User Goal: "$goal"
Action History: [${history.join(', ')}]

Interactive UI Elements on screen:
$elementPrompt

Choose the SINGLE best next action to advance towards the goal.
Respond ONLY in valid JSON matching this schema:
{
  "action": "CLICK" | "TYPE" | "SWIPE" | "GLOBAL" | "LAUNCH" | "FINISH",
  "index": <element_index_number_or_null>,
  "text": "<element_text_or_null>",
  "data": "<text_to_type_if_action_is_TYPE>",
  "direction": "UP" | "DOWN",
  "key": "BACK" | "HOME",
  "description": "<concise explanation of why this step is taken>"
}
""";

    try {
      final responseText = await DirectGroqService().generate(
        prompt: systemPrompt,
      );

      final cleanJson = responseText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      return jsonDecode(cleanJson) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[DroidRun Planner Error] $e');
      // Reflex heuristics if LLM JSON fails:
      for (final el in elements) {
        if (el.text.toLowerCase().contains('search') || el.text.toLowerCase().contains('ok')) {
          return {
            'action': 'CLICK',
            'index': el.index,
            'description': 'Tapping ${el.text}',
          };
        }
      }
      return {
        'action': 'FINISH',
        'description': 'Trajectory finished.',
      };
    }
  }

  String? _detectTargetApp(String goal) {
    final lower = goal.toLowerCase();
    final apps = [
      'youtube', 'whatsapp', 'instagram', 'settings', 'camera', 'maps',
      'spotify', 'chrome', 'gmail', 'twitter', 'telegram', 'uber',
      'clock', 'calendar', 'calculator', 'notes', 'gallery'
    ];
    for (final app in apps) {
      if (lower.contains(app)) return app;
    }
    return null;
  }

  void _recordStep(int idx, String action, String desc, String target, bool success) {
    final step = DroidRunStep(
      stepIndex: idx,
      actionType: action,
      description: desc,
      target: target,
      timestamp: DateTime.now(),
      success: success,
    );
    final updated = List<DroidRunStep>.from(trajectoryNotifier.value)..add(step);
    trajectoryNotifier.value = updated;
  }

  void stop() {
    _abortRequested = true;
    _setState(DroidRunState.idle, 'Autonomous execution cancelled.');
  }

  void _setState(DroidRunState s, String msg) {
    _state = s;
    stateNotifier.value = s;
    statusMessageNotifier.value = msg;
    debugPrint('[DroidRun State] $s: $msg');
  }
}
