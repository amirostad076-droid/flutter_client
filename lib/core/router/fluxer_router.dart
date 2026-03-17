import 'package:flutter/material.dart';
import 'package:fluxeron/core/providers/app_startup_provider.dart';
import 'package:fluxeron/core/router/route_names.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/auth/presentation/login_screen.dart';
import 'package:fluxeron/features/auth/presentation/mfa_screen.dart';
import 'package:fluxeron/features/chat/presentation/channel_layout.dart';
import 'package:fluxeron/features/dm/presentation/dm_layout.dart';
import 'package:fluxeron/features/notifications/presentation/notifications_page.dart';
import 'package:fluxeron/features/profile/presentation/profile_page.dart';
import 'package:fluxeron/features/settings/presentation/guild_settings_modal.dart';
import 'package:fluxeron/shared/widgets/splash_screen.dart';
import 'package:fluxeron/shared/widgets/reconnecting_screen.dart';
import 'package:fluxeron/shared/widgets/app_layout.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'fluxer_router.g.dart';

CustomTransitionPage<void> _fadeTransitionPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 150),
    reverseTransitionDuration: const Duration(milliseconds: 150),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

CustomTransitionPage<void> _slideTransitionPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 200),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final offsetAnimation = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut));
      return SlideTransition(position: offsetAnimation, child: child);
    },
  );
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.colors.backgroundSecondaryAlt,
    body: Center(child: Text(label)),
  );
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
      if (isAuthenticated && isReachable && (isLoggingIn || isOnReconnecting)) {
        return '/channels/@me';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/loading',
        builder: (context, state) => const SplashScreen(),
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
        builder: (context, state, child) => AppLayout(child: child),
        routes: [
          GoRoute(
            path: '/servers',
            name: RouteNames.servers,
            pageBuilder: (context, state) => _fadeTransitionPage(
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
                    return _fadeTransitionPage(
                      key: state.pageKey,
                      child: const _PlaceholderScreen('Invalid route'),
                    );
                  }
                  return _slideTransitionPage(
                    key: state.pageKey,
                    child: ChannelLayout(
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
            pageBuilder: (context, state) => _fadeTransitionPage(
              key: state.pageKey,
              child: const DMLayout(),
            ),
            routes: [
              GoRoute(
                path: ':dmId',
                name: RouteNames.dmChat,
                pageBuilder: (context, state) => _slideTransitionPage(
                  key: state.pageKey,
                  child: DMLayout(channelId: state.pathParameters['dmId']),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/notifications',
            name: RouteNames.notifications,
            pageBuilder: (context, state) => _fadeTransitionPage(
              key: state.pageKey,
              child: const NotificationsPage(),
            ),
          ),
          GoRoute(
            path: '/profile',
            name: RouteNames.profile,
            pageBuilder: (context, state) => _fadeTransitionPage(
              key: state.pageKey,
              child: const ProfilePage(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/settings/server/:serverId',
        name: RouteNames.serverSettings,
        builder: (context, state) => GuildSettingsModal(
          serverId: state.pathParameters['serverId'] ?? '',
        ),
      ),
    ],
  );
}
