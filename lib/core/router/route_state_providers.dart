import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/router/route_kind.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'route_state_providers.g.dart';

/// Snapshot of the router's current location plus its derived classification.
///
/// Consumers should prefer the dedicated providers ([currentLocationProvider],
/// [activeGuildIdProvider], [activeChannelIdProvider]) which `select` from
/// this state so they only rebuild when their field of interest changes.
@immutable
class RouteState {
  final String location;
  final RouteKind kind;
  final String? guildId;
  final String? channelId;

  const RouteState({
    required this.location,
    required this.kind,
    required this.guildId,
    required this.channelId,
  });

  factory RouteState.fromLocation(String location) => RouteState(
    location: location,
    kind: classifyRoute(location),
    guildId: extractGuildId(location),
    channelId: extractChannelId(location),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RouteState &&
          location == other.location &&
          kind == other.kind &&
          guildId == other.guildId &&
          channelId == other.channelId);

  @override
  int get hashCode => Object.hash(location, kind, guildId, channelId);
}

/// Single router-delegate listener that fans the matched location out
/// into a classified [RouteState]. Replaces three independent listeners
/// that previously each parsed the location with their own regex.
///
/// Prefer this over `GoRouterState.of(context)` — the app shell is
/// mounted via `StatefulShellRoute.indexedStack.pageBuilder`, and
/// go_router's state lookup is not available for descendants of a
/// `pageBuilder`.
@Riverpod(keepAlive: true)
class RouteStateNotifier extends _$RouteStateNotifier {
  @override
  RouteState build() {
    final router = ref.watch(fluxerRouterProvider);
    void listener() {
      // Per commit 2451be4: defer the state mutation by a microtask to
      // prevent "modifying state during build" errors when go_router
      // notifies its delegate while another widget is mid-build.
      unawaited(
        Future(() {
          state = RouteState.fromLocation(_readLocation(router));
        }),
      );
    }

    router.routerDelegate.addListener(listener);
    ref.onDispose(() => router.routerDelegate.removeListener(listener));
    return RouteState.fromLocation(_readLocation(router));
  }

  static String _readLocation(GoRouter router) {
    final config = router.routerDelegate.currentConfiguration;
    return config.isNotEmpty ? config.last.matchedLocation : '/';
  }
}

@Riverpod(keepAlive: true)
String currentLocation(Ref ref) {
  return ref.watch(routeStateProvider).location;
}

@Riverpod(keepAlive: true)
String? activeGuildId(Ref ref) {
  return ref.watch(routeStateProvider).guildId;
}

@Riverpod(keepAlive: true)
String? activeChannelId(Ref ref) {
  return ref.watch(routeStateProvider).channelId;
}
