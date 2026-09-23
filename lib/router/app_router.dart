import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/splash_screen.dart';
import '../screens/home_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/tasks_screen.dart';
import '../screens/library_screen.dart';
import '../screens/tools_screen.dart';
import '../screens/automations_screen.dart';
import '../screens/agent_builder_screen.dart';
import '../screens/autonomy_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/upgrade_screen.dart';
import '../screens/more_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../services/jack_auth_state.dart';

class AppRoutes {
  AppRoutes._();
  static const String splash        = '/';
  static const String login         = '/login';
  static const String register      = '/register';
  static const String dashboard     = '/dashboard';
  static const String home          = '/home';
  static const String chat          = '/chat';
  static const String tasks         = '/tasks';
  static const String library       = '/library';
  static const String tools         = '/tools';
  static const String automations   = '/automations';
  static const String agentBuilder  = '/agent-builder';
  static const String autonomy      = '/autonomy';
  static const String profile       = '/profile';
  static const String upgrade       = '/upgrade';
  static const String more          = '/more';
}

const _publicRoutes = {
  AppRoutes.splash,
  AppRoutes.login,
  AppRoutes.register,
};

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen<JackAuthState>(authStateProvider, (prev, next) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _RouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final path = state.uri.path;

      final isPublic = _publicRoutes.contains(path);
      final isAuthenticated = authState == JackAuthState.AUTHENTICATED;

      if (authState == JackAuthState.AUTHENTICATING && path == AppRoutes.splash) {
        return null;
      }

      if (!isAuthenticated && !isPublic) {
        return AppRoutes.login;
      }

      if (isAuthenticated && isPublic) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.library,
        builder: (context, state) => const LibraryScreen(),
      ),
      GoRoute(
        path: AppRoutes.agentBuilder,
        builder: (context, state) => const BuilderScreen(),
      ),
      GoRoute(
        path: AppRoutes.chat,
        builder: (context, state) =>
            ChatScreen(initialQuery: state.extra as String?),
      ),
      GoRoute(
        path: AppRoutes.tasks,
        builder: (context, state) => const TasksScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.tools,
        builder: (context, state) => const ToolsScreen(),
      ),
      GoRoute(
        path: AppRoutes.automations,
        builder: (context, state) => const AutomationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.autonomy,
        builder: (context, state) => const AutonomyScreen(),
      ),
      GoRoute(
        path: AppRoutes.upgrade,
        builder: (context, state) => const UpgradeScreen(),
      ),
      GoRoute(
        path: AppRoutes.more,
        builder: (context, state) => const MoreScreen(),
      ),
    ],
  );
});
