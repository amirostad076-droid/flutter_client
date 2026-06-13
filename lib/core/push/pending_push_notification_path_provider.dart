import 'package:fluxer_app/core/deep_links/deep_link_handler.dart';
import 'package:fluxer_app/core/providers/gateway_ready_provider.dart';
import 'package:fluxer_app/core/push/pending_push_notification_route.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/talker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pending_push_notification_path_provider.g.dart';

@Riverpod(keepAlive: true)
class PendingPushNotificationPath extends _$PendingPushNotificationPath {
  @override
  PendingPushNotificationRoute? build() {
    ref.listen<bool>(gatewayReadyProvider, (bool? previous, bool next) {
      if (!next) {
        return;
      }
      flushIfReady();
    });
    ref.listen<bool>(authStateProvider, (bool? previous, bool next) {
      if (!next) {
        return;
      }
      flushIfReady();
    });
    return null;
  }

  void store(String path) {
    state = PendingPushNotificationRoute(
      path: path,
      accountUserId: ref.read(currentUserIdProvider),
    );
    talker.info('[PushNotificationTap] Queued path until shell ready: $path');
    flushIfReady();
  }

  void clear() {
    state = null;
  }

  void flushIfReady() {
    final PendingPushNotificationRoute? pending = state;
    if (pending == null || pending.path.isEmpty) {
      return;
    }
    if (!ref.read(authStateProvider) || !ref.read(gatewayReadyProvider)) {
      return;
    }
    final String? currentUserId = ref.read(currentUserIdProvider);
    final String? accountUserId = pending.accountUserId;
    if (accountUserId != null &&
        accountUserId.isNotEmpty &&
        accountUserId != currentUserId) {
      state = null;
      talker.warning(
        '[PushNotificationTap] Dropped queued path for another account: '
        '${pending.path}',
      );
      return;
    }
    state = null;
    talker.info('[PushNotificationTap] Flushing queued path: ${pending.path}');
    ref.read(deepLinkHandlerProvider.notifier).handlePath(pending.path);
  }
}
