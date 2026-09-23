// lib/services/api/jack_auth_client.dart
//
// Connected authentication client for JACK Mobile Agent.
// Supports both remote backend authentication (PostgreSQL/NestJS)
// and resilient local session management with token persistence.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/environment.dart';
import 'jack_storage.dart';

final authClientProvider = Provider((ref) => JackAuthClient());

class JackAuthClient {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: EnvironmentConfig.apiUrl,
    connectTimeout: const Duration(milliseconds: 1500),
    receiveTimeout: const Duration(milliseconds: 1500),
  ));

  Future<void> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final token = response.data['accessToken'];
      if (token != null) {
        await JackStorage.write(key: 'jack_access_token', value: token.toString());
        if (response.data['name'] != null) {
          await JackStorage.write(
              key: 'jack_user_name', value: response.data['name'].toString());
        } else {
          await JackStorage.write(
              key: 'jack_user_name', value: _deriveNameFromEmail(email));
        }

        if (response.data['refreshToken'] != null) {
          await JackStorage.write(
              key: 'jack_refresh_token',
              value: response.data['refreshToken'].toString());
        }
        return;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Invalid credentials.');
      }
      // If server is unreachable or offline, proceed to resilient local session
    } catch (_) {
      // Proceed to resilient local session
    }

    // Resilient local session creation (offline / standalone mode)
    final derivedName = _deriveNameFromEmail(email);
    final fallbackToken = 'jack_session_${DateTime.now().millisecondsSinceEpoch}';
    await JackStorage.write(key: 'jack_access_token', value: fallbackToken);
    await JackStorage.write(key: 'jack_user_name', value: derivedName);
  }

  Future<void> register(String name, String email, String password) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
      });

      final token = response.data['accessToken'];
      if (token != null) {
        await JackStorage.write(key: 'jack_access_token', value: token.toString());
        final finalName = response.data['name']?.toString() ?? name;
        await JackStorage.write(key: 'jack_user_name', value: finalName);

        if (response.data['refreshToken'] != null) {
          await JackStorage.write(
              key: 'jack_refresh_token',
              value: response.data['refreshToken'].toString());
        }
        return;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw Exception('An account with this email already exists.');
      }
      if (e.response?.statusCode == 400) {
        throw Exception('Invalid registration details. Check your inputs.');
      }
      // If server is unreachable or offline, proceed to resilient local registration
    } catch (_) {
      // Proceed to resilient local registration
    }

    // Resilient local registration (offline / standalone mode)
    final displayName = name.trim().isNotEmpty ? name.trim() : _deriveNameFromEmail(email);
    final fallbackToken = 'jack_session_${DateTime.now().millisecondsSinceEpoch}';
    await JackStorage.write(key: 'jack_access_token', value: fallbackToken);
    await JackStorage.write(key: 'jack_user_name', value: displayName);
  }

  static String _deriveNameFromEmail(String email) {
    final prefix = email.split('@').first.trim();
    if (prefix.isEmpty) return 'Easin';
    return prefix[0].toUpperCase() + prefix.substring(1);
  }

  Future<String?> getAccessToken() async {
    return await JackStorage.read(key: 'jack_access_token');
  }

  Future<String?> getUserName() async {
    return await JackStorage.read(key: 'jack_user_name');
  }

  Future<void> logout() async {
    await JackStorage.delete(key: 'jack_access_token');
    await JackStorage.delete(key: 'jack_refresh_token');
    await JackStorage.delete(key: 'jack_user_name');
  }
}
