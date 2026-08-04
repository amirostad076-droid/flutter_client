import 'package:flutter/material.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/router/guild_root_redirect.dart';

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
    final String? uri = route.settings.name;
    if (uri == null || !uri.startsWith('/channels/')) {
      return;
    }
    persistGuildChannelFromLocation(db, uri);
  }
}
