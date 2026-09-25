// lib/services/jack_capabilities_service.dart
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_launcher_helper.dart';

/// Handles executing physical Android capabilities and interacting with the DOM.
/// The backend Agent Planner issues these commands to the Flutter app.
class JackCapabilitiesService {
  static const _platform = MethodChannel('com.jack.agent/accessibility');

  static Future<void> clickText(String text) async {
    await _platform.invokeMethod('clickText', {'text': text}).catchError((_) {});
  }

  static Future<void> typeText(String text) async {
    await _platform.invokeMethod('typeText', {'text': text}).catchError((_) {});
  }

  static Future<void> swipe(String direction) async {
    final dir = direction.toLowerCase();
    if (dir == 'down') {
      await _platform.invokeMethod('swipeDown').catchError((_) {});
    } else if (dir == 'left') {
      await _platform.invokeMethod('swipeLeft').catchError((_) {});
    } else if (dir == 'right') {
      await _platform.invokeMethod('swipeRight').catchError((_) {});
    } else {
      await _platform.invokeMethod('swipeUp').catchError((_) {});
    }
  }

  static Future<void> launchApp(String rawPkg) async {
    final pkg = await AppLauncherHelper.resolvePackage(rawPkg);
    await _platform.invokeMethod('launchApp', {'package': pkg}).catchError((_) {});
  }

  static Future<void> openUrl(String urlStr) async {
    final uri = Uri.tryParse(urlStr);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication).catchError((_) => false);
    }
  }

  static Future<void> directCall(String number) async {
    await _platform.invokeMethod('directCall', {'number': number}).catchError((_) {});
  }

  static Future<void> lockScreen() async {
    await _platform.invokeMethod('lockScreen').catchError((_) {});
  }

  static Future<void> setVolume(int level) async {
    await _platform.invokeMethod('setVolume', {'level': level}).catchError((_) {});
  }
  
  static Future<int> getBatteryLevel() async {
    return await _platform.invokeMethod<int>('getBatteryLevel') ?? -1;
  }

  static Future<void> pressBack() async {
    await _platform.invokeMethod('pressBack').catchError((_) {});
  }

  static Future<void> pressHome() async {
    await _platform.invokeMethod('pressHome').catchError((_) {});
  }

  static Future<void> pressRecents() async {
    await _platform.invokeMethod('pressRecents').catchError((_) {});
  }

  static Future<void> pullNotifications() async {
    await _platform.invokeMethod('pullNotifications').catchError((_) {});
  }

  static Future<void> pullQuickSettings() async {
    await _platform.invokeMethod('pullQuickSettings').catchError((_) {});
  }
}
