import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/router/route_kind.dart';

class ChannelPersistenceObserver extends NavigatorObserver {
  final FluxerDatabase db;

  ChannelPersistenceObserver(this.db);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _saveIfGuildChannel(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) {
      _saveIfGuildChannel(newRoute);
    }
  }

  void _saveIfGuildChannel(Route<dynamic> route) {
    final uri = route.settings.name;
    if (uri == null) {
      return;
    }
    // Classifier filters out guildMembers, dmCall, channelsRoot, nonChannel.
    if (classifyRoute(uri) != RouteKind.chat) {
      return;
    }
    // Strict two-segment shape: persist /channels/:guildId/:channelId only,
    // not message routes (/.../...). [^@/] excludes @me and @favorites.
    final match = RegExp(r'^/channels/([^@/][^/]*)/([^/]+)$').firstMatch(uri);
    if (match == null) {
      return;
    }
    final guildId = match.group(1)!;
    final channelId = match.group(2)!;
    unawaited(db.guildLastChannelDao.setLastChannel(guildId, channelId));
  }
}
