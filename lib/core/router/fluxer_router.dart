import 'package:flutter/material.dart';
import 'package:fluxeron/core/providers/app_startup_provider.dart';
import 'package:fluxeron/core/router/route_names.dart';
import 'package:fluxeron/core/theme/fluxer_colors.dart';
import 'package:fluxeron/features/auth/presentation/login_screen.dart';
import 'package:fluxeron/features/auth/presentation/mfa_screen.dart';
import 'package:fluxeron/features/chat/presentation/chat_screen.dart';
import 'package:fluxeron/features/dm/presentation/dm_screen.dart';
import 'package:fluxeron/features/notifications/presentation/notifications_page.dart';
import 'package:fluxeron/features/profile/presentation/profile_page.dart';
import 'package:fluxeron/features/settings/presentation/server_settings_screen.dart';
import 'package:fluxeron/shared/widgets/loading_screen.dart';
import 'package:fluxeron/shared/widgets/reconnecting_screen.dart';
import 'package:fluxeron/shared/widgets/responsive_shell.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'fluxer_router.g.dart';

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen(this.label);

  final String label;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(label)), backgroundColor: FluxerColors.backgroundAccent,);
}

@Riverpod(keepAlive: true)
class AuthState extends _$AuthState {
  @override
  bool build() => false;

  void setAuthenticated({required bool value}) {
    state = value;
  }
}

@Riverpod(keepAlive: true)
class CurrentUserId extends _$CurrentUserId {
  @override
  String? build() => null;

  void set(String id) {
    state = id;
  }
}

@Riverpod(keepAlive: true)
class ServerReachable extends _$ServerReachable {
  @override
  bool build() => true;

  void setReachable({required bool value}) {
    state = value;
  }
}

final rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

class _RouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

@Riverpod(keepAlive: true)
GoRouter fluxerRouter(Ref ref) {
  final refreshNotifier = _RouterRefreshNotifier();

  ref
    ..listen(authStateProvider, (_, _) => refreshNotifier.notify())
    ..listen(serverReachableProvider, (_, _) => refreshNotifier.notify())
    ..listen(appStartupProvider, (_, _) => refreshNotifier.notify());

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isOnLoading = location == '/loading';

      final isAuthenticated = ref.read(authStateProvider);
      final isReachable = ref.read(serverReachableProvider);
      final isStartupComplete = ref.read(appStartupProvider) is AsyncData;

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
        return '/channels/@me';
      }

      final isLoggingIn = location == '/login' || location == '/mfa';
      final isOnReconnecting = location == '/reconnecting';

      if (!isAuthenticated && !isLoggingIn) {
        return '/login';
      }
      if (isAuthenticated && !isReachable && !isOnReconnecting) {
        return '/reconnecting';
      }
      if (isAuthenticated &&
          isReachable &&
          (isLoggingIn || isOnReconnecting)) {
        return '/channels/@me';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/loading',
        builder: (context, state) => const LoadingScreen(),
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
        builder: (context, state, child) => ResponsiveShell(child: child),
        routes: [
          GoRoute(
            path: '/servers',
            name: RouteNames.servers,
            pageBuilder: (context, state) => NoTransitionPage<void>(
              key: state.pageKey,
              child: const _PlaceholderScreen('Select a channel'),
            ),
            routes: [
              GoRoute(
                path: ':serverId/channels/:channelId',
                name: RouteNames.channel,
                pageBuilder: (context, state) {
                  final serverId = state.pathParameters['serverId'];
                  final channelId = state.pathParameters['channelId'];
                  if (serverId == null || channelId == null) {
                    return const NoTransitionPage<void>(
                      child: _PlaceholderScreen('Invalid route'),
                    );
                  }
                  return NoTransitionPage<void>(
                    key: state.pageKey,
                    child: ChatScreen(
                      serverId: serverId,
                      channelId: channelId,
                    ),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/channels/@me',
            name: RouteNames.dms,
            pageBuilder: (context, state) => NoTransitionPage<void>(
              key: state.pageKey,
              child: const DmScreen(),
            ),
            routes: [
              GoRoute(
                path: ':dmId',
                name: RouteNames.dmChat,
                pageBuilder: (context, state) => NoTransitionPage<void>(
                  key: state.pageKey,
                  child:
                      DmScreen(channelId: state.pathParameters['dmId']),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/notifications',
            name: RouteNames.notifications,
            pageBuilder: (context, state) => NoTransitionPage<void>(
              key: state.pageKey,
              child: const NotificationsPage(),
            ),
          ),
          GoRoute(
            path: '/profile',
            name: RouteNames.profile,
            pageBuilder: (context, state) => NoTransitionPage<void>(
              key: state.pageKey,
              child: const ProfilePage(),
            ),
          ),
        ],
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
