import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:fluxer_app/core/providers/push_provider.dart';
import 'package:fluxer_app/core/push/local_push_notifications.dart';
import 'package:fluxer_app/core/push/push_message.dart';
import 'package:fluxer_app/core/router/route_names.dart';
import 'package:fluxer_app/core/router/route_state_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'push_notifications_coordinator.g.dart';

@Riverpod(keepAlive: true)
class PushNotificationsCoordinator extends _$PushNotificationsCoordinator {
  StreamSubscription<PushMessage>? _messageSubscription;
  final LocalPushNotifications _localPush = LocalPushNotifications();
  bool _homeBootstrapScheduled = false;

  @override
  bool build() {
    ref.listen(routeStateProvider, (RouteState? previous, RouteState next) {
      _maybeBootstrap(next.location);
    });
    _maybeBootstrap(ref.read(routeStateProvider).location);
    ref.onDispose(() {
      unawaited(_messageSubscription?.cancel());
      _messageSubscription = null;
    });
    return false;
  }

  void _maybeBootstrap(String location) {
    if (_homeBootstrapScheduled) {
      return;
    }
    if (location != RoutePaths.me) {
      return;
    }
    _homeBootstrapScheduled = true;
    unawaited(_runBootstrap());
  }

  Future<void> _runBootstrap() async {
    if (kIsWeb) {
      return;
    }
    try {
      await _localPush.ensureInitialized();
      await _localPush.requestDisplayPermission();
      final pushService = ref.read(pushServiceProvider);
      await pushService.requestPermissions();
      await pushService.initialize();
      await _messageSubscription?.cancel();
      _messageSubscription = pushService.watchMessages().listen(
        _localPush.showPushMessage,
        onError: (Object err, StackTrace st) {
          if (kDebugMode) {
            debugPrint('[PushNotificationsCoordinator] message stream: $err');
          }
        },
      );
    } on Object catch (e, st) {
      if (kDebugMode) {
        debugPrint('[PushNotificationsCoordinator] bootstrap failed: $e\n$st');
      }
    }
  }
}
