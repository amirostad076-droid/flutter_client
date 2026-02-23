import 'package:flutter/material.dart';
import 'package:fluxeron/core/providers/app_startup_provider.dart';
import 'package:fluxeron/core/router/route_names.dart';
import 'package:fluxeron/core/theme/fluxer_colors.dart';
import 'package:fluxeron/features/auth/presentation/login_screen.dart';
import 'package:fluxeron/features/auth/presentation/mfa_screen.dart';
import 'package:fluxeron/features/chat/presentation/chat_screen.dart';
import 'package:fluxeron/features/dm/presentation/dm_screen.dart';
import 'package:fluxeron/features/settings/presentation/server_settings_screen.dart';
import 'package:fluxeron/features/settings/presentation/user_settings_screen.dart';
import 'package:fluxeron/shared/widgets/fluxer_scaffold.dart';
import 'package:fluxeron/shared/widgets/reconnecting_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'fluxer_router.g.dart';

/// Placeholder screen used for routes not yet implemented.
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen(this.label);

  final String label;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(label)));
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: CircularProgressIndicator(color: FluxerColors.blurple)),
  );
}

/// Provides the auth session state for go_router redirect.
@Riverpod(keepAlive: true)
class AuthState extends _$AuthState {
  @override
  bool build() => false;

  void setAuthenticated({required bool value}) {
    state = value;
  }
}

/// Tracks whether the Fluxer servers are reachable.
@Riverpod(keepAlive: true)
class ServerReachable extends _$ServerReachable {
  @override
  bool build() => true;

  void setReachable({required bool value}) {
    state = value;
  }
}

/// Global navigator key for the captcha interceptor dialog.
final rootNavigatorKey = GlobalKey<NavigatorState>();

final _shellNavigatorKey = GlobalKey<NavigatorState>();

@Riverpod(keepAlive: true)
GoRouter fluxerRouter(Ref ref) {
  final isAuthenticated = ref.watch(authStateProvider);
  final isReachable = ref.watch(serverReachableProvider);
  final startupValue = ref.watch(appStartupProvider);
  final isStartupComplete = startupValue is AsyncData;

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/login',
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isOnLoading = location == '/loading';

      if (!isStartupComplete) {
        return isOnLoading ? null : '/loading';
      }

      if (isOnLoading) {
        if (!isAuthenticated) {
          return '/login';
        }
        if (!isReachable) {
          return '/reconnecting';
        }
        return '/servers';
      }

      final isLoggingIn = location == '/login' || location == '/mfa';
      final isOnReconnecting = location == '/reconnecting';

      if (!isAuthenticated && !isLoggingIn) {
        return '/login';
      }
      if (isAuthenticated && !isReachable && !isOnReconnecting) {
        return '/reconnecting';
      }
      if (isAuthenticated && isReachable && (isLoggingIn || isOnReconnecting)) {
        return '/servers';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/loading',
        builder: (context, state) => const _LoadingScreen(),
      ),
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/mfa',
        name: RouteNames.mfa,
        builder: (context, state) => const MfaScreen(),
      ),
      GoRoute(
        path: '/reconnecting',
        name: RouteNames.reconnecting,
        builder: (context, state) => const ReconnectingScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => FluxerScaffold(child: child),
        routes: [
          GoRoute(
            path: '/servers',
            name: RouteNames.servers,
            builder: (context, state) =>
                const _PlaceholderScreen('Select a channel'),
            routes: [
              GoRoute(
                path: ':serverId/channels/:channelId',
                name: RouteNames.channel,
                builder: (context, state) {
                  final serverId = state.pathParameters['serverId'];
                  final channelId = state.pathParameters['channelId'];
                  if (serverId == null || channelId == null) {
                    return const _PlaceholderScreen('Invalid route');
                  }
                  return ChatScreen(serverId: serverId, channelId: channelId);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/dms',
            name: RouteNames.dms,
            builder: (context, state) => const DmScreen(),
            routes: [
              GoRoute(
                path: ':dmId',
                name: RouteNames.dmChat,
                builder: (context, state) =>
                    DmScreen(channelId: state.pathParameters['dmId']),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/settings/user',
        name: RouteNames.userSettings,
        builder: (context, state) => const UserSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/server/:serverId',
        name: RouteNames.serverSettings,
        builder: (context, state) => ServerSettingsScreen(
          serverId: state.pathParameters['serverId'] ?? '',
        ),
      ),
    ],
  );
}
