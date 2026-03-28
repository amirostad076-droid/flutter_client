import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:fluxer_dart/export.dart';

import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/shared/utils/snowflake_time.dart';

/// Converts SDK [GuildResponse] to a Drift companion for upserting.
db.ServersCompanion guildFromSdk(
  GuildResponse sdk, {
  int position = 0,
  bool unavailable = false,
}) {
  return db.ServersCompanion.insert(
    id: sdk.id,
    name: sdk.name,
    icon: Value(sdk.icon),
    banner: Value(sdk.banner),
    ownerId: Value(sdk.ownerId),
    featuresJson: Value(jsonEncode(sdk.features)),
    position: Value(position),
    unavailable: Value(unavailable),
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
    lastMessageId: Value(sdk.lastMessageId),
  );
}

/// Converts SDK [GuildRoleResponse] to a Drift companion.
db.RolesCompanion roleFromSdk(GuildRoleResponse sdk, String serverId) {
  return db.RolesCompanion.insert(
    id: sdk.id,
    serverId: serverId,
    name: sdk.name,
    color: Value(sdk.color),
    position: Value(sdk.position),
    isHoisted: Value(sdk.hoist),
    permissions: Value(sdk.permissions),
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
    memberSince: Value(dateTimeFromUserSnowflakeOrNull(sdk.id)),
  );
}
