import 'package:drift/drift.dart';
import 'package:fluxer_dart/fluxer_dart.dart';

import 'package:fluxeron/core/database/fluxer_database.dart' as db;

/// Converts SDK [GuildResponse] to a Drift companion for upserting.
db.ServersCompanion serverFromSdk(GuildResponse sdk) {
  return db.ServersCompanion.insert(
    id: sdk.id,
    name: sdk.name,
    icon: Value(sdk.icon),
    banner: Value(sdk.banner),
    ownerId: Value(sdk.ownerId),
  );
}

/// Converts SDK [ChannelResponse] to a Drift companion for upserting.
db.ChannelsCompanion channelFromSdk(ChannelResponse sdk, String serverId) {
  return db.ChannelsCompanion.insert(
    id: sdk.id,
    serverId: serverId,
    name: sdk.name ?? '',
    type: Value(sdk.type),
    topic: Value(sdk.topic),
    parentId: Value(sdk.parentId),
    position: Value(sdk.position ?? 0),
  );
}

/// Converts SDK [UserPartialResponse] to a Drift companion.
db.UsersCompanion userFromPartialSdk(UserPartialResponse sdk) {
  return db.UsersCompanion.insert(
    id: sdk.id,
    username: sdk.username,
    discriminator: Value(sdk.discriminator),
    globalName: Value(sdk.globalName),
    avatar: Value(sdk.avatar),
    avatarColor: Value(sdk.avatarColor),
    isBot: Value(sdk.bot ?? false),
  );
}
