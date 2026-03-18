import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:fluxeron/core/router/fluxer_router.dart';
import 'package:fluxeron/core/router/route_names.dart';
import 'package:fluxeron/core/talker.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'deep_link_handler.g.dart';

@Riverpod(keepAlive: true)
class DeepLinkHandler extends _$DeepLinkHandler {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _subscription;
  Uri? _pendingDeepLink;

  @override
  void build() {
    _appLinks = AppLinks();

    _subscription = _appLinks.uriLinkStream.listen(
      _handleDeepLink,
      onError: (Object error) {
        talker.error('[DeepLink] Error receiving deep link: $error');
      },
    );

    ref.onDispose(() => _subscription?.cancel());

    unawaited(_checkInitialLink());
  }

  Future<void> _checkInitialLink() async {
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }
    } on Exception catch (e) {
      talker.error('[DeepLink] Error getting initial link: $e');
    }
  }

  void _handleDeepLink(Uri uri) {
    talker.info('[DeepLink] Received: $uri');

    final isAuthenticated = ref.read(authStateProvider);
    if (!isAuthenticated) {
      _pendingDeepLink = uri;
      talker.info('[DeepLink] Queued for after auth');
      return;
    }

    _processDeepLink(uri);
  }

  void processPendingDeepLink() {
    final pending = _pendingDeepLink;
    _pendingDeepLink = null;
    if (pending != null) {
      _processDeepLink(pending);
    }
  }

  void _processDeepLink(Uri uri) {
    final router = ref.read(fluxerRouterProvider);
    final segments = uri.pathSegments;

    if (segments.isEmpty) {
      return;
    }

    switch (segments.first) {
      case 'invite' when segments.length >= 2:
        router.go(RoutePaths.inviteLink(segments[1]));
      case 'gift' when segments.length >= 2:
        router.go(RoutePaths.giftLink(segments[1]));
      case 'users' when segments.length >= 2:
        talker.info('[DeepLink] User profile: ${segments[1]}');
      case 'channels':
        _handleChannelDeepLink(router, segments);
      default:
        talker.warning('[DeepLink] Unknown deep link path: ${uri.path}');
    }
  }

  void _handleChannelDeepLink(GoRouter router, List<String> segments) {
    if (segments.length >= 3 && segments[1] == '@me') {
      router.go(RoutePaths.dmChannel(segments[2]));
      return;
    }
    if (segments.length >= 4) {
      router.go(
        RoutePaths.guildChannelMessage(segments[1], segments[2], segments[3]),
      );
      return;
    }
    if (segments.length >= 3) {
      router.go(RoutePaths.guildChannel(segments[1], segments[2]));
      return;
    }
    if (segments.length >= 2) {
      router.go(RoutePaths.guild(segments[1]));
      return;
    }
  }
}
