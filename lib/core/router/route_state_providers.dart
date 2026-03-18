import 'package:fluxeron/core/router/fluxer_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'route_state_providers.g.dart';

/// Watches the router location and extracts the active guild ID.
/// Returns null for @me, @favorites, and non-channel routes.
@Riverpod(keepAlive: true)
class ActiveGuildId extends _$ActiveGuildId {
  @override
  String? build() {
    final router = ref.watch(fluxerRouterProvider);

    void listener() {
      final location =
          router.routerDelegate.currentConfiguration.last.matchedLocation;
      state = _extractGuildId(location);
    }

    router.routerDelegate.addListener(listener);
    ref.onDispose(() => router.routerDelegate.removeListener(listener));

    return null;
  }

  static String? _extractGuildId(String location) {
    // Matches /channels/:guildId where guildId is NOT @me or @favorites
    final match = RegExp(r'^/channels/([^@/][^/]*)').firstMatch(location);
    return match?.group(1);
  }
}

/// Watches the router location and extracts the active channel ID.
/// Works for both guild channels and DM channels.
@Riverpod(keepAlive: true)
class ActiveChannelId extends _$ActiveChannelId {
  @override
  String? build() {
    final router = ref.watch(fluxerRouterProvider);

    void listener() {
      final location =
          router.routerDelegate.currentConfiguration.last.matchedLocation;
      state = _extractChannelId(location);
    }

    router.routerDelegate.addListener(listener);
    ref.onDispose(() => router.routerDelegate.removeListener(listener));

    return null;
  }

  static String? _extractChannelId(String location) {
    // /channels/@me/:channelId
    final dmMatch = RegExp(r'^/channels/@me/([^/]+)$').firstMatch(location);
    if (dmMatch != null) {
      return dmMatch.group(1);
    }

    // /channels/@favorites/:channelId
    final favMatch = RegExp(
      r'^/channels/@favorites/([^/]+)$',
    ).firstMatch(location);
    if (favMatch != null) {
      return favMatch.group(1);
    }

    // /channels/:guildId/:channelId (not "members")
    final guildMatch = RegExp(
      r'^/channels/[^@/][^/]*/([^/]+)',
    ).firstMatch(location);
    if (guildMatch != null && guildMatch.group(1) != 'members') {
      return guildMatch.group(1);
    }

    return null;
  }
}
