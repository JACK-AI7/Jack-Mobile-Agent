import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/agent/agent.dart';
import '../../models/tool/tool_definition.dart';
import '../../models/agent/jack_agent_request.dart';
import '../../models/task_model.dart';
import '../../models/automation_model.dart';
import '../../config/environment.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final apiClientProvider = Provider((ref) {
  const secureStorage = FlutterSecureStorage();
  return JackApiClient(secureStorage);
});

class JackApiClient {
  final FlutterSecureStorage _secureStorage;
  late final Dio _dio;

  JackApiClient(this._secureStorage) {
    _dio = Dio(BaseOptions(
      baseUrl: EnvironmentConfig.apiUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ));

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorage.read(key: 'jack_access_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
            return handler.next(options);
          } else {
            // Do not send authenticated requests if no token exists.
            return handler.reject(
              DioException(
                requestOptions: options,
                error: 'Authentication required. No valid access token found.',
                type: DioExceptionType.cancel,
              ),
            );
          }
        },
        onError: (DioException e, handler) {
          if (e.response?.statusCode == 401) {
            // Note: Refresh token logic would go here, but backend lacks a /auth/refresh endpoint.
            // Marking REFRESH TOKEN: NOT IMPLEMENTED.
            return handler.reject(
              DioException(
                requestOptions: e.requestOptions,
                error: 'Authentication/session expired.',
                type: DioExceptionType.badResponse,
              ),
            );
          } else if (e.response?.statusCode == 403) {
            return handler.reject(
              DioException(
                requestOptions: e.requestOptions,
                error: 'Authenticated but unauthorized to access this resource.',
                type: DioExceptionType.badResponse,
              ),
            );
          }
          return handler.next(e);
        },
      ),
    );
  }

  // --- Agents ---
  
  Future<List<Agent>> listAgents() async {
    try {
      final response = await _dio.get('/agents');
      final data = response.data as List;
      return data.map((e) => Agent.fromJson(e)).toList();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Backend Unavailable. JACK is offline.');
      }
      throw Exception('Failed to load agents: ${e.message}');
    }
  }

  Future<Agent> createAgent(String prompt) async {
    try {
      final response = await _dio.post('/agents', data: {'prompt': prompt});
      return Agent.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to create agent: ${e.message}');
    }
  }

  Future<JackAgentResponse> executeAgent(JackAgentRequest request) async {
    try {
      final response = await _dio.post('/agents/execute', data: request.toJson());
      return JackAgentResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Backend Unavailable. JACK is offline.');
      }
      throw Exception('Failed to execute agent: ${e.message}');
    }
  }

  // --- Tools ---

  Future<List<ToolDefinition>> listTools() async {
    try {
      final response = await _dio.get('/tools');
      final data = response.data as List;
      return data.map((e) => ToolDefinition.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to load tools: ${e.message}');
    }
  }
  Future<void> approveExecution(String executionId) async {
    try {
      await _dio.post('/agents/execute/$executionId/approve');
    } on DioException catch (e) {
      throw Exception('Failed to approve execution: ' + e.message.toString());
    }
  }

  Future<void> rejectExecution(String executionId) async {
    try {
      await _dio.post('/agents/execute/$executionId/reject');
    } on DioException catch (e) {
      throw Exception('Failed to reject execution: ' + e.message.toString());
    }
  }


  // --- Tasks ---
  Future<List<TaskModel>> listTasks() async {
    try {
      final response = await _dio.get('/tasks');
      return (response.data as List).map((e) => TaskModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load tasks: ');
    }
  }

  // --- Automations ---
  Future<List<AutomationModel>> listAutomations() async {
    try {
      final response = await _dio.get('/automations');
      return (response.data as List).map((e) => AutomationModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load automations: ');
    }
  }

  Future<void> toggleAutomation(String id, bool isActive) async {
    try {
      await _dio.patch('/automations/', data: {'isActive': isActive});
    } catch (e) {
      throw Exception('Failed to toggle automation: ');
    }
  }

  Future<void> createAutomation(String name, String schedule) async {
    try {
      await _dio.post('/automations', data: {'name': name, 'schedule': schedule});
    } catch (e) {
      throw Exception('Failed to create automation: ');
    }
  }
  Future<void> deleteAutomation(String id) async {
    try {
      await _dio.delete('/automations/');
    } catch (e) {
      throw Exception('Failed to delete automation: ');
    }
  }
}