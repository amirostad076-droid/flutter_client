import 'package:fluxer_app/core/deep_links/deep_link_handler.dart';
import 'package:fluxer_app/core/providers/gateway_ready_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/talker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pending_push_notification_path_provider.g.dart';

@Riverpod(keepAlive: true)
class PendingPushNotificationPath extends _$PendingPushNotificationPath {
  @override
  String? build() {
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
    state = path;
    talker.info('[PushNotificationTap] Queued path until shell ready: $path');
    flushIfReady();
  }

  void flushIfReady() {
    final String? path = state;
    if (path == null || path.isEmpty) {
      return;
    }
    if (!ref.read(authStateProvider) || !ref.read(gatewayReadyProvider)) {
      return;
    }
    state = null;
    talker.info('[PushNotificationTap] Flushing queued path: $path');
    ref.read(deepLinkHandlerProvider.notifier).handlePath(path);
  }
}
