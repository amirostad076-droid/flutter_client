import 'package:drift/drift.dart';

import 'package:fluxeron/core/database/fluxer_database.dart' as db;

const fluxerMediaCdn = 'https://fluxerusercontent.com';

class Server {
  final String id;
  final String name;
  final String? icon;
  final String? banner;
  final int memberCount;
  final int onlineCount;
  final String? description;
  final String? ownerId;
  final int position;

  const Server({
    required this.id,
    required this.name,
    this.icon,
    this.banner,
    this.memberCount = 0,
    this.onlineCount = 0,
    this.description,
    this.ownerId,
    this.position = 0,
  });

  factory Server.fromRow(db.Server row) {
    return Server(
      id: row.id,
      name: row.name,
      icon: row.icon,
      banner: row.banner,
      memberCount: row.memberCount,
      onlineCount: row.onlineCount,
      description: row.description,
      ownerId: row.ownerId,
      position: row.position,
    );
  }

  db.ServersCompanion toCompanion() {
    return db.ServersCompanion.insert(
      id: id,
      name: name,
      icon: Value(icon),
      banner: Value(banner),
      memberCount: Value(memberCount),
      onlineCount: Value(onlineCount),
      description: Value(description),
      ownerId: Value(ownerId),
      position: Value(position),
    );
  }

  String? get iconUrl {
    if (icon == null) {
      return null;
    }
    return '$fluxerMediaCdn/icons/$id/$icon.png';
  }

  String? get bannerUrl {
    if (banner == null) {
      return null;
    }
    return '$fluxerMediaCdn/banners/$id/$banner.png';
  }
}
