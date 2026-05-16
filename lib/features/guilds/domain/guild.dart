import 'dart:convert';

import 'package:drift/drift.dart';

import 'package:fluxer_app/core/database/fluxer_database.dart' as db;

const fluxerMediaCdn = 'https://fluxerusercontent.com';

class Guild {
  final String id;
  final String name;
  final String? icon;
  final String? banner;
  final int memberCount;
  final int onlineCount;
  final String? description;
  final String? ownerId;
  final int position;
  final List<String> features;
  final bool unavailable;

  const Guild({
    required this.id,
    required this.name,
    this.icon,
    this.banner,
    this.memberCount = 0,
    this.onlineCount = 0,
    this.description,
    this.ownerId,
    this.position = 0,
    this.features = const [],
    this.unavailable = false,
  });

  factory Guild.fromRow(db.Server row) {
    return Guild(
      id: row.id,
      name: row.name,
      icon: row.icon,
      banner: row.banner,
      memberCount: row.memberCount,
      onlineCount: row.onlineCount,
      description: row.description,
      ownerId: row.ownerId,
      position: row.position,
      features: (jsonDecode(row.featuresJson) as List<dynamic>).cast<String>(),
      unavailable: row.unavailable,
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
      featuresJson: Value(jsonEncode(features)),
      unavailable: Value(unavailable),
    );
  }

  bool get isVerified => features.contains('VERIFIED');
  bool get isPartnered => features.contains('PARTNERED');
  bool get isDiscoverable => features.contains('DISCOVERABLE');
  bool get isUnavailable =>
      unavailable || features.contains('UNAVAILABLE_FOR_EVERYONE_BUT_STAFF');

  bool get hasAnimatedIcon => icon?.startsWith('a_') ?? false;
  bool get hasAnimatedBanner => banner?.startsWith('a_') ?? false;

  String? get iconUrl {
    if (icon == null) {
      return null;
    }
    if (hasAnimatedIcon) {
      return '$fluxerMediaCdn/icons/$id/$icon.webp?animated=false';
    }
    return '$fluxerMediaCdn/icons/$id/$icon.png';
  }

  String? get animatedIconUrl {
    if (icon == null || !hasAnimatedIcon) {
      return null;
    }
    return '$fluxerMediaCdn/icons/$id/$icon.gif?animated=true';
  }

  String? get bannerUrl {
    if (banner == null) {
      return null;
    }
    if (hasAnimatedBanner) {
      return '$fluxerMediaCdn/banners/$id/$banner.gif?animated=true&size=1024';
    }
    return '$fluxerMediaCdn/banners/$id/$banner.png?size=1024';
  }
}
