import 'package:flutter/material.dart';
import 'package:fluxeron/core/database/fluxer_database.dart';

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
    final match = RegExp(r'^/channels/([^@/][^/]*)/([^/]+)$').firstMatch(uri);
    if (match != null) {
      final guildId = match.group(1)!;
      final channelId = match.group(2)!;
      if (channelId != 'members') {
        db.guildLastChannelDao.setLastChannel(guildId, channelId);
      }
    }
  }
}
