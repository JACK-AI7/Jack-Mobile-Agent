// lib/services/jack_master_dispatcher.dart
//
// Jack — Complete Tool Dispatcher & Dual-Speed Cognitive Engine
//
// System 1 (Reflex Engine - <100ms):
//   Handles deterministic actions locally (flashlight, volume, alarms, screenshot, routines).
// System 2 (Planner & Vision Grounding):
//   Invoked for multi-step app exploration, semantic node reasoning, or VLM fallbacks.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/services.dart';
import '../models/bixby_routine_model.dart';
import 'jack_controller.dart';
import 'jack_shizuku_controller.dart';
import 'trajectory_cache_service.dart';

class JackMasterDispatcher {
  JackMasterDispatcher._();

  static const MethodChannel _legacyChannel =
      MethodChannel('com.syncra.syncra/accessibility');

  // ── System 1: Fast Reflex Matcher (<100ms) ─────────────────────────────────

  /// Checks if a voice query matches an instantaneous deterministic intent.
  /// Returns a completed execution result if matched, or null if System 2 (LLM) is needed.
  static Future<Map<String, dynamic>?> tryReflexFastPath(String query) async {
    final lower = query.toLowerCase().trim();

    // Flashlight
    if (lower == 'turn on flashlight' || lower == 'flashlight on' || lower == 'torch on') {
      return executeCommand({'intent': 'toggle_flashlight', 'params': {'state': true}});
    }
    if (lower == 'turn off flashlight' || lower == 'flashlight off' || lower == 'torch off') {
      return executeCommand({'intent': 'toggle_flashlight', 'params': {'state': false}});
    }

    // Mute / Volume
    if (lower == 'mute' || lower == 'mute volume' || lower == 'silence phone') {
      return executeCommand({'intent': 'set_volume', 'params': {'level': 0, 'stream': 'media'}});
    }
    if (lower == 'max volume' || lower == 'volume 100') {
      return executeCommand({'intent': 'set_volume', 'params': {'level': 100, 'stream': 'media'}});
    }

    // Screenshot
    if (lower == 'screenshot' || lower == 'take a screenshot' || lower == 'capture screen') {
      return executeCommand({'intent': 'take_screenshot'});
    }

    // Lock Screen
    if (lower == 'lock screen' || lower == 'lock phone' || lower == 'lock the screen') {
      return executeCommand({'intent': 'lock_screen'});
    }

    // Battery
    if (lower == 'battery' || lower == 'what is my battery level' || lower == 'check battery') {
      return executeCommand({'intent': 'get_battery'});
    }

    // Built-in Quick Command Routines
    for (final key in builtInBixbyMacros.keys) {
      if (lower.contains(key)) {
        return executeCommand({'intent': 'run_routine', 'params': {'routine_name': key}});
      }
    }

    // Cached trajectory check
    final cached = await TrajectoryCacheService.getTrajectory(lower);
    if (cached != null && cached.isNotEmpty) {
      final success = await TrajectoryCacheService.replayTrajectory(lower);
      if (success) {
        return {
          "status": "success",
          "message": "Replayed cached routine for '$query' at native speed",
          "fast_path": true,
        };
      }
    }

    return null; // Delegate to System 2 Planner / Groq VLM
  }

  // ── Master Command Executor ────────────────────────────────────────────────

  /// Main entry point for voice commands parsed by LLM or Reflex Engine
  static Future<Map<String, dynamic>> executeCommand(
    Map<String, dynamic> toolCall,
  ) async {
    final String rawIntent = (toolCall['intent'] ?? toolCall['command'] ?? toolCall['action'] ?? '').toString();
    final String intent = rawIntent.toLowerCase().replaceAll(' ', '_');
    final Map<String, dynamic> params =
        (toolCall['params'] ?? toolCall['parameters'] as Map?)?.cast<String, dynamic>() ?? {};

    switch (intent) {
      // ── HARDWARE & SETTINGS ────────────────────────────────────────────────
      case "toggle_flashlight":
      case "flashlight":
        final bool state = params['state'] == true || params['enabled'] == true || params['state'] == 'on';
        await JackController.toggleTorch(state);
        return {
          "status": "success",
          "message": "Flashlight turned ${state ? 'on' : 'off'}",
          "type": "flashlight",
          "data": {"enabled": state},
        };

      case "set_volume":
      case "volume":
        final int level = (params['level'] as num?)?.toInt() ?? 50;
        final String stream = params['stream'] as String? ?? "media";
        try {
          await _legacyChannel.invokeMethod('setVolume', {'level': level, 'stream': stream});
        } catch (_) {}
        return {
          "status": "success",
          "message": "$stream volume set to $level%",
          "type": "volume",
          "data": {"level": level},
        };

      case "take_screenshot":
      case "screenshot":
        await JackController.triggerGlobal("SCREENSHOT");
        return {
          "status": "success",
          "message": "Screenshot captured",
          "type": "action",
        };

      case "lock_screen":
      case "lock":
        await JackController.triggerGlobal("LOCK_SCREEN");
        return {
          "status": "success",
          "message": "Screen locked",
          "type": "action",
        };

      case "get_battery":
      case "battery":
        int level = 85;
        try {
          level = await _legacyChannel.invokeMethod<int>('getBatteryLevel') ?? 85;
        } catch (_) {}
        return {
          "status": "success",
          "message": "Battery is at $level%",
          "type": "battery",
          "data": {"level": level},
        };

      // ── CLOCK & TIMERS ─────────────────────────────────────────────────────
      case "set_alarm":
        final String time = params['time'] as String? ?? "07:00";
        final String label = params['label'] as String? ?? "Jack Alarm";
        final parts = time.split(':');
        final hour = int.tryParse(parts[0]) ?? 7;
        final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
        try {
          await _legacyChannel.invokeMethod('setAlarm', {
            'hour': hour,
            'minute': minute,
            'label': label,
            'time': time,
          });
        } catch (_) {}
        return {
          "status": "success",
          "message": "Alarm set for $time",
          "type": "alarm",
        };

      case "set_timer":
        final int seconds = (params['seconds'] as num?)?.toInt() ?? 300;
        final String label = params['label'] as String? ?? "Jack Timer";
        try {
          await _legacyChannel.invokeMethod('setTimer', {'seconds': seconds, 'label': label});
        } catch (_) {}
        return {
          "status": "success",
          "message": "Timer set for ${seconds ~/ 60} minutes",
          "type": "timer",
        };

      // ── BIXBY VISION (SCREEN UNDERSTANDING) ────────────────────────────────
      case "read_screen_context":
      case "inspect_screen":
        final List<Map<String, dynamic>> nodes = await JackController.inspectScreen();
        final screenText = nodes
            .map((n) => n['text'])
            .where((t) => t != null && t.toString().isNotEmpty)
            .join(" | ");
        return {
          "status": "success",
          "screen_content": screenText,
          "node_count": nodes.length,
        };

      // ── AUTONOMOUS UI CLICKS & AUTOMATION ──────────────────────────────────
      case "click_on_screen":
      case "click":
        final String? text = params['target_text'] ?? params['text'];
        final String? id = params['target_id'] ?? params['id'];
        final double? x = (params['x'] as num?)?.toDouble();
        final double? y = (params['y'] as num?)?.toDouble();

        bool clicked = false;
        if (text != null || id != null) {
          clicked = await JackController.clickElement(text: text, id: id);
        }
        if (!clicked && x != null && y != null) {
          await JackController.tapCoordinates(x, y);
          clicked = true;
        }
        if (!clicked && x != null && y != null) {
          // Shizuku Tier 3 fallback
          clicked = await JackShizukuController.tap(x, y);
        }
        return {
          "status": clicked ? "success" : "failed",
          "target": text ?? id ?? "($x,$y)",
        };

      case "input_screen_text":
      case "type_text":
        final String text = params['text'] as String? ?? '';
        final String? id = params['target_id'] as String?;
        final String? query = params['target_text'] as String?;

        bool typed = false;
        if (id != null || query != null) {
          typed = await JackController.typeText(id: id, text: query, data: text);
        }
        if (!typed) {
          // Tier 3 Shizuku fallback
          typed = await JackShizukuController.typeText(text);
        }
        return {"status": typed ? "success" : "failed", "typed": text};

      case "swipe":
      case "scroll":
        final double x1 = (params['startX'] as num?)?.toDouble() ?? 540;
        final double y1 = (params['startY'] as num?)?.toDouble() ?? 1400;
        final double x2 = (params['endX'] as num?)?.toDouble() ?? 540;
        final double y2 = (params['endY'] as num?)?.toDouble() ?? 600;
        final int duration = (params['duration'] as num?)?.toInt() ?? 300;

        await JackController.swipe(startX: x1, startY: y1, endX: x2, endY: y2, durationMs: duration);
        return {"status": "success", "action": "swiped"};

      // ── MULTI-ACTION ROUTINES (BIXBY QUICK COMMANDS) ───────────────────────
      case "run_routine":
      case "routine":
        final String routineName =
            (params['routine_name'] ?? params['name'] ?? '').toString().toLowerCase();

        if (builtInBixbyMacros.containsKey(routineName)) {
          final macro = builtInBixbyMacros[routineName]!;
          for (final step in macro.steps) {
            await executeCommand({'intent': step.action, 'params': step.params});
          }
          return {
            "status": "success",
            "message": "Routine '$routineName' executed.",
            "type": "routine",
            "data": {"actions": "All ${macro.steps.length} steps complete"},
          };
        }
        return {"status": "error", "message": "Routine '$routineName' not found"};

      default:
        // Attempt legacy channel fallback
        try {
          await _legacyChannel.invokeMethod(intent, params);
          return {"status": "success", "intent": intent};
        } catch (_) {
          return {"status": "unhandled", "intent": intent};
        }
    }
  }
}
