// lib/services/jack_shizuku_controller.dart
//
// Jack — Privileged ADB-Level Shell Controller via Shizuku
// Runs on-device without USB cable or PC, giving Jack UID 2000 shell authority.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/services.dart';

class JackShizukuController {
  JackShizukuController._();

  static const MethodChannel _channel = MethodChannel('com.jack.agent/shizuku');

  /// Check if Shizuku is running and permission is granted
  static Future<Map<String, bool>> checkStatus() async {
    try {
      final Map<dynamic, dynamic>? res = await _channel.invokeMethod('checkStatus');
      return {
        "available": res?["available"] == true,
        "hasPermission": res?["hasPermission"] == true,
      };
    } catch (_) {
      return {"available": false, "hasPermission": false};
    }
  }

  /// Returns true if Shizuku is both available and authorized
  static Future<bool> isReady() async {
    final status = await checkStatus();
    return status['available'] == true && status['hasPermission'] == true;
  }

  /// Trigger Shizuku system permission popup
  static Future<bool> requestPermission() async {
    try {
      await _channel.invokeMethod('requestPermission');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// ADB Shell Tap: `input tap x y`
  static Future<bool> tap(double x, double y) async {
    try {
      final bool? success = await _channel.invokeMethod('execTap', {'x': x, 'y': y});
      return success ?? false;
    } catch (_) {
      return false;
    }
  }

  /// ADB Shell Swipe: `input swipe x1 y1 x2 y2 duration`
  static Future<bool> swipe(
    double x1,
    double y1,
    double x2,
    double y2, {
    int duration = 300,
  }) async {
    try {
      final bool? success = await _channel.invokeMethod('execSwipe', {
        'x1': x1,
        'y1': y1,
        'x2': x2,
        'y2': y2,
        'duration': duration,
      });
      return success ?? false;
    } catch (_) {
      return false;
    }
  }

  /// ADB Shell Input Text (escapes spaces and special chars)
  static Future<bool> typeText(String text) async {
    try {
      final bool? success = await _channel.invokeMethod('execText', {'text': text});
      return success ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Execute any privileged ADB shell command
  static Future<String> executeShell(String cmd) async {
    try {
      final String? output = await _channel.invokeMethod('execRaw', {'cmd': cmd});
      return output ?? '';
    } catch (e) {
      return 'ERROR: $e';
    }
  }
}
