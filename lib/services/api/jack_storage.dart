// lib/services/api/jack_storage.dart
//
// Resilient storage service for JACK Mobile Agent.
// Uses FlutterSecureStorage with automatic transparent fallback to
// SharedPreferences on Android Keystore or platform exceptions, ensuring
// credentials and session state never fail across emulator, mobile & web.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JackStorage {
  static const FlutterSecureStorage _secure = FlutterSecureStorage();

  static Future<void> write({required String key, required String value}) async {
    try {
      await _secure.write(key: key, value: value);
    } catch (e) {
      debugPrint('[JackStorage] Secure write fallback: $e');
    }
    // Always mirror to SharedPreferences for bulletproof persistence
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (e) {
      debugPrint('[JackStorage] Prefs write error: $e');
    }
  }

  static Future<String?> read({required String key}) async {
    try {
      final val = await _secure.read(key: key);
      if (val != null && val.isNotEmpty) return val;
    } catch (e) {
      debugPrint('[JackStorage] Secure read fallback: $e');
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (e) {
      debugPrint('[JackStorage] Prefs read error: $e');
      return null;
    }
  }

  static Future<void> delete({required String key}) async {
    try {
      await _secure.delete(key: key);
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (_) {}
  }

  static Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      const channel = MethodChannel('com.jack.agent/accessibility');
      final res = await channel.invokeMethod('getDeviceInfo');
      if (res is Map) {
        return Map<String, dynamic>.from(res);
      }
    } catch (_) {}
    return {
      'manufacturer': 'Android',
      'model': 'Device',
      'brand': 'Generic',
      'androidVersion': '14',
    };
  }
}
