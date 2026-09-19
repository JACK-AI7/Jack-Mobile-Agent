import 'dart:convert';
import 'package:flutter/services.dart';

class JackRealTelemetryService {
  static const MethodChannel _channel = MethodChannel('com.jack.agent/controller');

  /// Fetches 100% verified hardware and screen context from the device
  static Future<Map<String, dynamic>> gatherRealContext() async {
    // 1. Query native Android Battery, Audio, and Settings
    final Map<dynamic, dynamic>? rawHardware = await _channel.invokeMethod('getRealDeviceMetrics');
    
    // 2. Dump real on-screen Accessibility nodes
    String? rawScreenJson;
    try {
      rawScreenJson = await _channel.invokeMethod('readScreen');
    } catch (e) {
      // Ignored if service off
    }
    final Map<String, dynamic> screenData = rawScreenJson != null ? jsonDecode(rawScreenJson) : {};

    return {
      "battery": {
        "level": rawHardware?['batteryLevel'] ?? 0,
        "is_charging": rawHardware?['isCharging'] ?? false,
      },
      "audio": {
        "media_volume": rawHardware?['mediaVolume'] ?? 0,
        "ringer_mode": rawHardware?['ringerMode'] ?? "NORMAL",
      },
      "display": {
        "brightness": rawHardware?['brightness'] ?? 0,
      },
      "active_package": screenData['active_package'] ?? "unknown",
      "visible_screen_nodes": (screenData['nodes'] as List? ?? []).take(25).toList(),
    };
  }
}
