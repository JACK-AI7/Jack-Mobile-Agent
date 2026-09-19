import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../config/environment.dart';

final authClientProvider = Provider((ref) => JackAuthClient());

class JackAuthClient {
  final Dio _dio = Dio(BaseOptions(baseUrl: EnvironmentConfig.apiUrl));
  final _secureStorage = const FlutterSecureStorage();

  Future<void> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      
      final token = response.data['accessToken'];
      if (token == null) {
        throw Exception('Server did not return a valid token.');
      }
      
      // Save safely to secure storage
      await _secureStorage.write(key: 'jack_access_token', value: token);
      if (response.data['name'] != null) {
        await _secureStorage.write(key: 'jack_user_name', value: response.data['name']);
      }
      
      if (response.data['refreshToken'] != null) {
        await _secureStorage.write(key: 'jack_refresh_token', value: response.data['refreshToken']);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Invalid credentials.');
      }
      throw Exception('Authentication failed.');
    }
  }

  Future<void> register(String name, String email, String password) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
      });

      final token = response.data['accessToken'];
      if (token == null) {
        throw Exception('Server did not return a valid token.');
      }

      // Persist tokens securely
      await _secureStorage.write(key: 'jack_access_token', value: token);
      if (response.data['name'] != null) {
        await _secureStorage.write(key: 'jack_user_name', value: response.data['name']);
      }
      
      if (response.data['refreshToken'] != null) {
        await _secureStorage.write(key: 'jack_refresh_token', value: response.data['refreshToken']);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw Exception('An account with this email already exists.');
      }
      if (e.response?.statusCode == 400) {
        throw Exception('Invalid registration details. Check your inputs.');
      }
      throw Exception('Registration failed. Please try again.');
    }
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: 'jack_access_token');
  }
  
  Future<String?> getUserName() async {
    return await _secureStorage.read(key: 'jack_user_name');
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: 'jack_access_token');
    await _secureStorage.delete(key: 'jack_refresh_token');
  }
}
