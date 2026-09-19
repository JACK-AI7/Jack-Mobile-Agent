
class EnvironmentConfig {
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');
  
  // Note: For Android Emulator, localhost is usually 10.0.2.2.
  // Using localhost here assuming it runs on Web, Desktop, or iOS Simulator, 
  // or that the developer sets up port forwarding.
  // Replace the production URL with your actual Railway generated domain.
  static const String localApiUrl = 'http://localhost:3000';
  static const String prodApiUrl = 'https://jack-mobile-agent-production.up.railway.app';
  static const String devApiUrl = 'http://10.0.2.2:3000'; // Android emulator local loopback

  static String get apiUrl {
    if (isProduction) {
      return prodApiUrl;
    }
    return localApiUrl;
  }
}
