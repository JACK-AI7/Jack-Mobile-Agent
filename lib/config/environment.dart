
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class EnvironmentConfig {
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');
  
  static const String localApiUrl = 'http://localhost:3000';
  static const String prodApiUrl = 'https://jack-mobile-agent-production.up.railway.app';
  static const String devApiUrl = 'http://10.0.2.2:3000'; // Android emulator local loopback

  static String get apiUrl {
    if (isProduction) {
      return prodApiUrl;
    }
    if (!kIsWeb && Platform.isAndroid) {
      return devApiUrl;
    }
    return localApiUrl;
  }
}
