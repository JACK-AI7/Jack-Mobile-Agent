import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api/jack_auth_client.dart';

enum JackAuthState {
  UNAUTHENTICATED,
  AUTHENTICATING,
  AUTHENTICATED,
  SESSION_EXPIRED,
}

class JackAuthNotifier extends StateNotifier<JackAuthState> {
  final JackAuthClient _authClient;
  final FlutterSecureStorage _secureStorage;

  JackAuthNotifier(this._authClient, this._secureStorage) : super(JackAuthState.UNAUTHENTICATED) {
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    final token = await _secureStorage.read(key: 'jack_access_token');
    if (token != null && token.isNotEmpty) {
      state = JackAuthState.AUTHENTICATED;
    } else {
      state = JackAuthState.UNAUTHENTICATED;
    }
  }

  Future<void> login(String email, String password) async {
    state = JackAuthState.AUTHENTICATING;
    try {
      await _authClient.login(email, password);
      state = JackAuthState.AUTHENTICATED;
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
    } catch (e) {
      state = JackAuthState.UNAUTHENTICATED;
      rethrow;
    }
  }

  Future<void> logout() async {
    await _authClient.logout();
    state = JackAuthState.UNAUTHENTICATED;
  }

  void markSessionExpired() {
    state = JackAuthState.SESSION_EXPIRED;
  }

  void markAuthenticated() {
    state = JackAuthState.AUTHENTICATED;
  }
}

final authStateProvider = StateNotifierProvider<JackAuthNotifier, JackAuthState>((ref) {
  final client = ref.watch(authClientProvider);
  return JackAuthNotifier(client, const FlutterSecureStorage());
});

final userNameProvider = FutureProvider<String?>((ref) async {
  // Watch auth state to re-trigger on login/logout
  ref.watch(authStateProvider);
  final client = ref.watch(authClientProvider);
  return await client.getUserName();
});
