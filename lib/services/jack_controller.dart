// lib/services/jack_controller.dart
//
// Jack — Autonomous Screen Controller (Flutter Bridge)
// Wraps the JackMasterAccessibilityService Kotlin via MethodChannel
// Channel: com.jack.agent/controller
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:convert';
import 'package:flutter/services.dart';

class JackController {
  JackController._();

  static const MethodChannel _channel =
      MethodChannel('com.jack.agent/controller');

  // ── Service Status ─────────────────────────────────────────────────────────

  /// Returns true if the JackMasterAccessibilityService is active.
  static Future<bool> isAccessibilityActive() async {
    try {
      final bool active =
          await _channel.invokeMethod('isAccessibilityActive');
      return active;
    } catch (_) {
      return false;
    }
  }

  /// Opens Android Accessibility Settings so the user can enable the service.
  static Future<void> openAccessibilitySettings() async {
    await _channel.invokeMethod('openAccessibilitySettings');
  }

  // ── Vision: Screen Reading ─────────────────────────────────────────────────

  /// Dumps the full on-screen UI node hierarchy as a list of maps.
  /// Each map contains: id, text, clickable, bounds {left,top,right,bottom,centerX,centerY}
  static Future<List<Map<String, dynamic>>> inspectScreen() async {
    try {
      final String rawJson = await _channel.invokeMethod('readScreen');
      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
      final List<dynamic> nodes = decoded['nodes'] ?? [];
      return nodes.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  // ── Action: UI Automation ──────────────────────────────────────────────────

  /// Clicks on a UI element matching [id] (resource ID) or [text] (label).
  static Future<bool> clickElement({String? id, String? text}) async {
    try {
      final bool success = await _channel.invokeMethod('clickNode', {
        'id': id,
        'text': text,
      });
      return success;
    } catch (_) {
      return false;
    }
  }

  /// Taps exact screen pixel coordinates.
  static Future<void> tapCoordinates(double x, double y) async {
    await _channel.invokeMethod('clickCoords', {'x': x, 'y': y});
  }

  /// Types [data] into the input field matching [id] or [text].
  static Future<bool> typeText({
    String? id,
    String? text,
    required String data,
  }) async {
    try {
      final bool success = await _channel.invokeMethod('typeText', {
        'id': id,
        'text': text,
        'data': data,
      });
      return success;
    } catch (_) {
      return false;
    }
  }

  /// Performs a swipe gesture from start to end in [durationMs] milliseconds.
  static Future<void> swipe({
    required double startX,
    required double startY,
    required double endX,
    required double endY,
    int durationMs = 300,
  }) async {
    await _channel.invokeMethod('swipe', {
      'startX': startX,
      'startY': startY,
      'endX': endX,
      'endY': endY,
      'duration': durationMs,
    });
  }

  // ── Action: System Global Controls ────────────────────────────────────────

  /// Triggers a global system action.
  /// Valid actions: BACK, HOME, RECENTS, NOTIFICATIONS, QUICK_SETTINGS,
  ///                SCREENSHOT, LOCK_SCREEN
  static Future<bool> triggerGlobal(String action) async {
    try {
      final bool success = await _channel.invokeMethod('globalAction', {
        'action': action,
      });
      return success;
    } catch (_) {
      return false;
    }
  }

  // ── Action: Hardware ───────────────────────────────────────────────────────

  /// Toggles the device flashlight / torch.
  static Future<bool> toggleTorch(bool enable) async {
    try {
      final bool state = await _channel.invokeMethod('toggleFlashlight', {
        'enable': enable,
      });
      return state;
    } catch (_) {
      return false;
    }
  }
}
