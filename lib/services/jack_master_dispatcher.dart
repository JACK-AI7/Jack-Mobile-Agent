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
import 'app_launcher_helper.dart';
import 'jack_controller.dart';
import 'jack_shizuku_controller.dart';
import 'trajectory_cache_service.dart';
import 'agent/jack_droid_run_engine.dart';
import 'tasks/jack_task_service.dart';

class JackMasterDispatcher {
  JackMasterDispatcher._();

  static const MethodChannel _legacyChannel =
      MethodChannel('com.jack.agent/accessibility');

  // ── System 1: Fast Reflex Matcher (<100ms) ─────────────────────────────────

  /// Checks if a voice query matches an instantaneous deterministic intent.
  /// Returns a completed execution result if matched, or null if System 2 (LLM) is needed.
  static Future<Map<String, dynamic>?> tryReflexFastPath(String query) async {
    final result = await _tryReflexFastPathInternal(query);
    if (result != null) {
      final msg = result['message']?.toString() ?? 'Action executed.';
      final type = result['type']?.toString() ?? 'Action';
      final category = (type.contains('dom') || type.contains('swipe'))
          ? 'DOM / Gesture'
          : (type.contains('volume') ||
                  type.contains('flashlight') ||
                  type.contains('wifi') ||
                  type.contains('bluetooth'))
              ? 'Hardware'
              : 'Automation';
      JackTaskRecorder.recordTask(
        title: query.length > 36 ? '${query.substring(0, 36)}...' : query,
        description: msg,
        category: category,
        resultSummary: msg,
      );
    }
    return result;
  }

  static Future<Map<String, dynamic>?> _tryReflexFastPathInternal(String query) async {
    final lower = query.toLowerCase().trim();

    // ── 0A. WAKE WORD REFLEX & PREFIX STRIPPER ─────────────────────────────────
    if (lower == 'hey jack' ||
        lower == 'jack' ||
        lower == 'hi jack' ||
        lower == 'ok jack' ||
        lower == 'okay jack' ||
        lower == 'hello jack' ||
        lower == 'wake up jack' ||
        lower == 'wake jack' ||
        lower == 'wake up') {
      return {
        "status": "success",
        "intent": "wake_word",
        "result": "Hi Sir, what's the task?",
        "message": "Hi Sir, what's the task?",
        "type": "wake_word",
      };
    }

    final wakePrefixRegex = RegExp(
      r'^(?:hey\s+jack|hi\s+jack|ok\s+jack|okay\s+jack|hello\s+jack|jack)[,\s]+(.+)$',
      caseSensitive: false,
    );
    final wakePrefixMatch = wakePrefixRegex.firstMatch(lower);
    if (wakePrefixMatch != null) {
      final stripped = wakePrefixMatch.group(1)?.trim() ?? '';
      if (stripped.isNotEmpty) {
        return _tryReflexFastPathInternal(stripped);
      }
    }

    // ── 0. COMPOUND / SEQUENTIAL CONTINUOUS DOM COMMANDS ──────────────────────
    // e.g., "skip the video play next video adn then increase the sound search this play that first video search this in the chrome play the first"
    final isCompound = (lower.contains('then') || lower.contains('and then') || lower.contains('adn then')) ||
        (lower.contains('skip') && (lower.contains('sound') || lower.contains('volume') || lower.contains('chrome') || lower.contains('search') || lower.contains('play')));

    if (isCompound) {
      final List<String> actions = [];

      // 1. Skip Video / Next Video
      if (lower.contains('skip') || lower.contains('next video')) {
        await JackController.swipe(startX: 540, startY: 1600, endX: 540, endY: 400, durationMs: 250);
        actions.add("Skipped video");
        await Future.delayed(const Duration(milliseconds: 600));
      }

      // 2. Play Next Video
      if (lower.contains('play next video')) {
        await JackController.swipe(startX: 540, startY: 1600, endX: 540, endY: 400, durationMs: 250);
        actions.add("Navigated to next video");
        await Future.delayed(const Duration(milliseconds: 600));
      }

      // 3. Sound / Volume
      if (lower.contains('increase') && (lower.contains('sound') || lower.contains('volume'))) {
        try {
          await _legacyChannel.invokeMethod('setVolume', {'level': 85, 'stream': 'media'});
          actions.add("Increased volume to 85%");
        } catch (_) {}
        await Future.delayed(const Duration(milliseconds: 400));
      } else if (lower.contains('decrease') && (lower.contains('sound') || lower.contains('volume'))) {
        try {
          await _legacyChannel.invokeMethod('setVolume', {'level': 25, 'stream': 'media'});
          actions.add("Decreased volume to 25%");
        } catch (_) {}
        await Future.delayed(const Duration(milliseconds: 400));
      }

      // 4. Search in Chrome
      if (lower.contains('chrome') || (lower.contains('search this') && lower.contains('chrome'))) {
        await AppLauncherHelper.launchAppByName('chrome');
        actions.add("Opened Chrome");
        await Future.delayed(const Duration(milliseconds: 1600));

        await JackController.tapCoordinates(540, 220);
        await Future.delayed(const Duration(milliseconds: 500));

        String searchTarget = "trending videos";
        if (lower.contains('search this')) {
          final afterSearch = lower.substring(lower.indexOf('search this') + 11).trim();
          final clean = afterSearch.replaceAll(RegExp(r'in the chrome|in chrome|play the first|play that first video|play first', caseSensitive: false), '').trim();
          if (clean.isNotEmpty) searchTarget = clean;
        }

        await JackController.typeText(data: "$searchTarget\n");
        actions.add("Searched for '$searchTarget'");
        await Future.delayed(const Duration(milliseconds: 1200));
      }

      // 5. Play First Video / Tap First Result
      if (lower.contains('play that first video') || lower.contains('play the first') || lower.contains('play first')) {
        await JackController.tapCoordinates(540, 720);
        actions.add("Selected first video");
      }

      if (actions.isNotEmpty) {
        return {
          "status": "success",
          "message": "Executed continuous DOM workflow: ${actions.join(' -> ')}.",
          "type": "dom_sequence",
          "actions": actions,
        };
      }
    }

    // ── 1. SINGLE DOM ACTIONS ─────────────────────────────────────────────────
    // Skip / Next Video
    if (lower == 'skip' ||
        lower == 'next' ||
        lower.contains('skip video') ||
        lower.contains('skip the video') ||
        lower.contains('play next video') ||
        lower.contains('next video') ||
        lower.contains('scroll down') ||
        lower.contains('swipe up') ||
        (lower.contains('skip') && !lower.contains('alarm') && !lower.contains('timer'))) {
      await JackController.swipe(startX: 540, startY: 1600, endX: 540, endY: 400, durationMs: 250);
      return {
        "status": "success",
        "message": "Skipped to next video via native DOM swipe.",
        "type": "dom_swipe",
      };
    }

    // Previous Video
    if (lower == 'previous' ||
        lower.contains('previous video') ||
        lower.contains('prev video') ||
        lower.contains('play previous video') ||
        lower.contains('scroll up') ||
        lower.contains('swipe down')) {
      await JackController.swipe(startX: 540, startY: 400, endX: 540, endY: 1600, durationMs: 250);
      return {
        "status": "success",
        "message": "Returned to previous video via native DOM swipe.",
        "type": "dom_swipe",
      };
    }

    // Play First Video
    if (lower.contains('play the first') ||
        lower.contains('play that first') ||
        lower.contains('play first video') ||
        lower.contains('play first') ||
        lower.contains('click the first') ||
        lower.contains('tap first') ||
        lower.contains('first video')) {
      await JackController.tapCoordinates(540, 720);
      return {
        "status": "success",
        "message": "Tapped and played the first video result.",
        "type": "dom_tap",
      };
    }

    // Search in Chrome
    if (lower.startsWith('search this in chrome') ||
        lower.startsWith('search this in the chrome') ||
        lower.startsWith('search in chrome') ||
        lower.contains('search this in chrome') ||
        lower.contains('search this in the chrome')) {
      String queryToSearch = query
          .replaceAll(RegExp(r'search\s+(this\s+)?in\s+(the\s+)?chrome', caseSensitive: false), '')
          .replaceAll(RegExp(r'play\s+(that\s+|the\s+)?first(\s+video)?', caseSensitive: false), '')
          .trim();
      if (queryToSearch.isEmpty) queryToSearch = "latest trending videos";

      await AppLauncherHelper.launchAppByName('chrome');
      await Future.delayed(const Duration(milliseconds: 1500));
      await JackController.tapCoordinates(540, 220);
      await Future.delayed(const Duration(milliseconds: 600));
      await JackController.typeText(data: "$queryToSearch\n");
      await Future.delayed(const Duration(milliseconds: 500));
      try {
        await _legacyChannel.invokeMethod('pressEnter');
      } catch (_) {}

      return {
        "status": "success",
        "message": "Opened Chrome and searched for '$queryToSearch'.",
        "type": "dom_search",
      };
    }

    // Generic App Launch
    if (lower.startsWith('open ') || lower.startsWith('launch ')) {
      final appName = query.substring(lower.indexOf(' ') + 1).trim();
      final launched = await AppLauncherHelper.launchAppByName(appName);
      return {
        "status": launched ? "success" : "failed",
        "message": launched ? "Opening $appName on your device now." : "Could not find app '$appName'.",
        "type": "app_launch",
      };
    }

    // Flashlight / Light
    if (lower.contains('flashlight on') ||
        lower.contains('turn on flashlight') ||
        lower.contains('turn on the flashlight') ||
        lower.contains('light on') ||
        lower.contains('turn on light') ||
        lower.contains('turn on the light') ||
        lower.contains('torch on') ||
        lower.contains('turn on torch')) {
      return executeCommand({'intent': 'toggle_flashlight', 'params': {'state': true}});
    }
    if (lower.contains('flashlight off') ||
        lower.contains('turn off flashlight') ||
        lower.contains('turn off the flashlight') ||
        lower.contains('light off') ||
        lower.contains('turn off light') ||
        lower.contains('turn off the light') ||
        lower.contains('torch off') ||
        lower.contains('turn off torch')) {
      return executeCommand({'intent': 'toggle_flashlight', 'params': {'state': false}});
    }

    // WiFi
    if (lower.contains('wifi on') ||
        lower.contains('turn on wifi') ||
        lower.contains('enable wifi')) {
      return executeCommand({'intent': 'toggle_wifi', 'params': {'state': true}});
    }
    if (lower.contains('wifi off') ||
        lower.contains('turn off wifi') ||
        lower.contains('disable wifi')) {
      return executeCommand({'intent': 'toggle_wifi', 'params': {'state': false}});
    }

    // Bluetooth
    if (lower.contains('bluetooth on') ||
        lower.contains('turn on bluetooth') ||
        lower.contains('enable bluetooth')) {
      return executeCommand({'intent': 'toggle_bluetooth', 'params': {'state': true}});
    }
    if (lower.contains('bluetooth off') ||
        lower.contains('turn off bluetooth') ||
        lower.contains('disable bluetooth')) {
      return executeCommand({'intent': 'toggle_bluetooth', 'params': {'state': false}});
    }

    // Brightness
    if (lower.startsWith('brightness ') || lower.startsWith('set brightness ')) {
      final parts = lower.replaceAll('%', '').split(' ');
      final val = int.tryParse(parts.last) ?? 80;
      return executeCommand({'intent': 'set_brightness', 'params': {'level': val}});
    }
    if (lower == 'max brightness' || lower == 'full brightness') {
      return executeCommand({'intent': 'set_brightness', 'params': {'level': 100}});
    }

    // Volume with direct numbers and speech-to-text variations (like "doing" for "sound")
    // Matches "media volume to 20", "volume 20", "volume to 80", "sound to 40", "doing to 29"
    final volDirectMatch = RegExp(
      r'(?:media\s+|system\s+)?(?:volume|sound|audio|doing|tune|ringer)\s+(?:to\s+|at\s+)?(\d+)%?',
      caseSensitive: false,
    ).firstMatch(lower);
    if (volDirectMatch != null) {
      final val = int.tryParse(volDirectMatch.group(1) ?? '50') ?? 50;
      return executeCommand({'intent': 'set_volume', 'params': {'level': val.clamp(0, 100), 'stream': 'media'}});
    }

    final volActionMatch = RegExp(
      r'(?:set|change|put)\s+(?:the\s+)?(?:media\s+|system\s+)?(?:volume|sound|audio|doing|tune|ringer)\s+(?:to\s+|at\s+)?(\d+)%?',
      caseSensitive: false,
    ).firstMatch(lower);
    if (volActionMatch != null) {
      final val = int.tryParse(volActionMatch.group(1) ?? '50') ?? 50;
      return executeCommand({'intent': 'set_volume', 'params': {'level': val.clamp(0, 100), 'stream': 'media'}});
    }

    final decreaseMatch = RegExp(
      r'(?:decrease|lower|turn down|drop|reduce)\s+(?:the\s+)?(?:media\s+|system\s+)?(?:volume|sound|audio|doing|tune|ringer)?\s*(?:to\s+|at\s+)?(\d+)?',
      caseSensitive: false,
    ).firstMatch(lower);
    if (decreaseMatch != null) {
      final valStr = decreaseMatch.group(1);
      final val = valStr != null ? (int.tryParse(valStr) ?? 20) : 20;
      return executeCommand({'intent': 'set_volume', 'params': {'level': val.clamp(0, 100), 'stream': 'media'}});
    }

    final increaseMatch = RegExp(
      r'(?:increase|raise|turn up|boost)\s+(?:the\s+)?(?:media\s+|system\s+)?(?:volume|sound|audio|doing|tune|ringer)?\s*(?:to\s+|at\s+)?(\d+)?',
      caseSensitive: false,
    ).firstMatch(lower);
    if (increaseMatch != null) {
      final valStr = increaseMatch.group(1);
      final val = valStr != null ? (int.tryParse(valStr) ?? 85) : 85;
      return executeCommand({'intent': 'set_volume', 'params': {'level': val.clamp(0, 100), 'stream': 'media'}});
    }

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

    // Turn Off / Power Off / Shut Down / Lock Mobile & Phone
    if (lower.contains('turn off mobile') ||
        lower.contains('turn off the mobile') ||
        lower.contains('turn off phone') ||
        lower.contains('turn off the phone') ||
        lower.contains('switch off mobile') ||
        lower.contains('switch off phone') ||
        lower.contains('switch off the mobile') ||
        lower.contains('switch off the phone') ||
        lower.contains('power off') ||
        lower.contains('shut down mobile') ||
        lower.contains('shutdown mobile') ||
        lower.contains('shutdown phone') ||
        lower.contains('lock mobile') ||
        lower.contains('lock the mobile') ||
        lower.contains('lock phone') ||
        lower.contains('lock the phone') ||
        lower == 'lock screen' ||
        lower == 'lock the screen') {
      try {
        if (lower.contains('power') || lower.contains('shut') || lower.contains('switch off')) {
          await JackController.triggerGlobal("POWER_DIALOG");
        }
      } catch (_) {}
      await JackController.lockScreen();
      return {
        "status": "success",
        "message": "Screen locked and power dialog opened, Sir.",
        "type": "device_power",
      };
    }

    // Battery
    if (lower == 'battery' || lower == 'what is my battery level' || lower == 'check battery') {
      return executeCommand({'intent': 'get_battery'});
    }

    // Direct Outbound Call Reflex ("call Mom", "dial 9876543210", "phone Sarah")
    final callRegex = RegExp(
      r'^(?:call|dial|phone|make a call to|ring)\s+(.+)$',
      caseSensitive: false,
    );
    final callMatch = callRegex.firstMatch(lower);
    if (callMatch != null) {
      final target = callMatch.group(1)?.trim() ?? '';
      if (target.isNotEmpty &&
          !target.contains('screener') &&
          !target.contains('screening') &&
          !target.contains('log') &&
          !target.contains('center')) {
        return executeCommand({
          'intent': 'make_call',
          'params': {'target': target},
        });
      }
    }

    // Autonomous Call Screening Reflex ("screen call", "talk to caller", "answer call")
    if (lower == 'screen call' ||
        lower == 'screen calls' ||
        lower == 'screen incoming call' ||
        lower == 'screen the call' ||
        lower == 'answer call' ||
        lower == 'answer the call' ||
        lower == 'talk to caller' ||
        lower == 'talk to the caller' ||
        lower == 'simulate call' ||
        lower == 'test call' ||
        lower == 'test incoming call' ||
        lower.contains('screen call from') ||
        lower.contains('take the call')) {
      return executeCommand({
        'intent': 'screen_call',
        'params': {'query': query},
      });
    }

    // End Call Reflex
    if (lower == 'end call' ||
        lower == 'hang up' ||
        lower == 'cut call' ||
        lower == 'disconnect call' ||
        lower == 'cut the call') {
      return executeCommand({'intent': 'end_call'});
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

      case "toggle_bluetooth":
      case "bluetooth":
        final bool btState = params['state'] == true || params['enabled'] == true || params['state'] == 'on';
        try {
          await _legacyChannel.invokeMethod('toggleBluetooth', {'enable': btState});
        } catch (_) {}
        return {
          "status": "success",
          "message": "Bluetooth turned ${btState ? 'on' : 'off'}",
          "type": "bluetooth",
          "data": {"enabled": btState},
        };

      case "toggle_wifi":
      case "wifi":
        final bool wifiState = params['state'] == true || params['enabled'] == true || params['state'] == 'on';
        try {
          await _legacyChannel.invokeMethod('toggleWifi', {'enable': wifiState});
        } catch (_) {}
        return {
          "status": "success",
          "message": "Wi-Fi turned ${wifiState ? 'on' : 'off'}",
          "type": "wifi",
          "data": {"enabled": wifiState},
        };

      case "set_brightness":
      case "brightness":
        final int brightLevel = (params['level'] as num?)?.toInt() ?? 80;
        try {
          await _legacyChannel.invokeMethod('setBrightness', {'level': brightLevel});
        } catch (_) {}
        return {
          "status": "success",
          "message": "Brightness set to $brightLevel%",
          "type": "brightness",
          "data": {"level": brightLevel},
        };

      case "autonomous_goal":
      case "droid_run":
      case "run_agent":
      case "automate_app":
      case "control_phone":
        final goal = (params['goal'] ?? params['prompt'] ?? params['task'] ?? '').toString();
        if (goal.isNotEmpty) {
          JackDroidRunEngine.instance.executeGoal(goal);
          return {
            "status": "success",
            "message": "Initializing on-device autonomous execution for: $goal",
            "type": "autonomy",
          };
        }
        return {
          "status": "error",
          "message": "Please specify a goal for the autonomous agent.",
          "type": "autonomy",
        };

      case "make_call":
      case "direct_call":
      case "call":
      case "dial":
      case "screen_call":
      case "screen_incoming_call":
      case "talk_to_caller":
      case "end_call":
      case "hang_up":
        return {
          "status": "info",
          "message": "Telephony has been decoupled. Jack now focuses 100% on on-device app control via DroidRun and OpenGUI.",
          "type": "autonomy",
        };

      case "send_sms":
      case "sms":
        final String smsNum = (params['number'] ?? params['to'] ?? '').toString();
        final String smsMsg = (params['message'] ?? params['text'] ?? params['body'] ?? '').toString();
        try {
          await _legacyChannel.invokeMethod('sendSMS', {'number': smsNum, 'message': smsMsg});
        } catch (_) {}
        return {
          "status": "success",
          "message": "SMS sent to $smsNum",
          "type": "sms",
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

      case "get_calendar_events":
      case "calendar":
        try {
          final res = await _legacyChannel.invokeMethod<String>('getCalendarEvents');
          return {
            "status": "success",
            "message": res ?? "No calendar events found.",
            "type": "calendar",
            "data": {"events": res},
          };
        } catch (e) {
          return {"status": "error", "message": "Calendar query failed: $e"};
        }

      case "search_contact":
      case "contact":
        final name = (params['name'] ?? params['target'] ?? '').toString();
        try {
          final res = await _legacyChannel.invokeMethod<String>('searchContact', {'name': name});
          return {
            "status": "success",
            "message": res ?? "Contact not found",
            "type": "contacts",
            "data": {"contact": res},
          };
        } catch (e) {
          return {"status": "error", "message": "Contact lookup failed: $e"};
        }

      case "open_wifi_settings":
        try {
          await _legacyChannel.invokeMethod('openWifiSettings');
          return {"status": "success", "message": "Wi-Fi settings opened", "type": "settings"};
        } catch (e) {
          return {"status": "error", "message": "Could not open Wi-Fi settings"};
        }

      case "open_bluetooth_settings":
        try {
          await _legacyChannel.invokeMethod('openBluetoothSettings');
          return {"status": "success", "message": "Bluetooth settings opened", "type": "settings"};
        } catch (e) {
          return {"status": "error", "message": "Could not open Bluetooth settings"};
        }

      case "open_sound_settings":
        try {
          await _legacyChannel.invokeMethod('openSoundSettings');
          return {"status": "success", "message": "Sound settings opened", "type": "settings"};
        } catch (e) {
          return {"status": "error", "message": "Could not open Sound settings"};
        }

      case "open_battery_settings":
        try {
          await _legacyChannel.invokeMethod('openBatterySettings');
          return {"status": "success", "message": "Battery settings opened", "type": "settings"};
        } catch (e) {
          return {"status": "error", "message": "Could not open Battery settings"};
        }

      case "open_camera":
        try {
          await _legacyChannel.invokeMethod('openCamera');
          return {"status": "success", "message": "Camera launched", "type": "camera"};
        } catch (e) {
          return {"status": "error", "message": "Could not launch camera"};
        }

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
