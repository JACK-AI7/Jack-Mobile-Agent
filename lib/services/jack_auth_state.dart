import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api/jack_auth_client.dart';
import 'realtime/agent_execution_controller.dart';

enum JackAuthState {
  UNAUTHENTICATED,
  AUTHENTICATING,
  AUTHENTICATED,
  SESSION_EXPIRED,
}

class JackAuthNotifier extends StateNotifier<JackAuthState> {
  final JackAuthClient _authClient;
  final FlutterSecureStorage _secureStorage;
  final Ref _ref;

  JackAuthNotifier(this._authClient, this._secureStorage, this._ref)
      : super(JackAuthState.UNAUTHENTICATED) {
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    final token = await _secureStorage.read(key: 'jack_access_token');
    if (token != null && token.isNotEmpty) {
      state = JackAuthState.AUTHENTICATED;
      // Restore app-level socket connection on cold start
      _ref.read(agentExecutionProvider.notifier).connectIfAuthenticated(token);
    } else {
      state = JackAuthState.UNAUTHENTICATED;
    }
  }

  Future<void> login(String email, String password) async {
    state = JackAuthState.AUTHENTICATING;
    try {
      await _authClient.login(email, password);
      state = JackAuthState.AUTHENTICATED;
      // Establish app-level socket connection after successful login
      final token = await _authClient.getAccessToken();
      if (token != null) {
        _ref.read(agentExecutionProvider.notifier).connectIfAuthenticated(token);
      }
    } catch (e) {
      state = JackAuthState.UNAUTHENTICATED;
      rethrow;
    }
  }

  Future<void> register(String name, String email, String password) async {
    state = JackAuthState.AUTHENTICATING;
    try {
      await _authClient.register(name, email, password);
      state = JackAuthState.AUTHENTICATED;
      // Establish app-level socket connection after successful registration
      final token = await _authClient.getAccessToken();
      if (token != null) {
        _ref.read(agentExecutionProvider.notifier).connectIfAuthenticated(token);
      }
    } catch (e) {
      state = JackAuthState.UNAUTHENTICATED;
      rethrow;
    }
  }

  Future<void> logout() async {
    // Tear down socket before clearing credentials
    _ref.read(agentExecutionProvider.notifier).disconnect();
    await _authClient.logout();
    state = JackAuthState.UNAUTHENTICATED;
  }

  void markSessionExpired() {
    _ref.read(agentExecutionProvider.notifier).disconnect();
    state = JackAuthState.SESSION_EXPIRED;
  }

  void markAuthenticated() {
    state = JackAuthState.AUTHENTICATED;
  }
}

final authStateProvider = StateNotifierProvider<JackAuthNotifier, JackAuthState>((ref) {
  final client = ref.watch(authClientProvider);
  return JackAuthNotifier(client, const FlutterSecureStorage(), ref);
});

final userNameProvider = FutureProvider<String?>((ref) async {
  // Watch auth state to re-trigger on login/logout
  ref.watch(authStateProvider);
  final client = ref.watch(authClientProvider);
  return await client.getUserName();
});
