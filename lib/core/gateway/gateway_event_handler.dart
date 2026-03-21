import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:fluxer_dart/export.dart';
import 'package:fluxer_dart/gateway.dart';

import 'package:fluxeron/core/database/fluxer_database.dart' as db;
import 'package:fluxeron/core/talker.dart';
import 'package:fluxeron/features/chat/domain/message.dart';
import 'package:fluxeron/shared/utils/sdk_converters.dart';

typedef TypingCallback = void Function(String channelId, String userId);

class GatewayEventHandler {
  GatewayEventHandler({required this.database, this.onTypingStart});

  final db.FluxerDatabase database;
  final TypingCallback? onTypingStart;

  void handle(GatewayEvent event) {
    switch (event) {
      case ReadyEvent():
        _handleReady(event);
      case ResumedEvent():
        talker.info('[Gateway] Session resumed');
      case MessageCreateEvent():
        _handleMessageCreate(event);
      case MessageUpdateEvent():
        _handleMessageUpdate(event);
      case MessageDeleteEvent():
        _handleMessageDelete(event);
      case TypingStartEvent():
        _handleTypingStart(event);
      case PresenceUpdateEvent():
        _handlePresenceUpdate(event);
      case GuildMemberAddEvent():
        _handleMemberUpsert(event.guildId, event.member);
      case GuildMemberUpdateEvent():
        _handleMemberUpsert(event.guildId, event.member);
      case GuildMemberRemoveEvent():
        _handleMemberRemove(event);
      case ChannelCreateEvent():
        _handleChannelUpsert(event.channel);
      case ChannelUpdateEvent():
        _handleChannelUpsert(event.channel);
      case ChannelDeleteEvent():
        _handleChannelDelete(event);
      case MessageReactionAddEvent():
        _handleReactionAdd(event);
      case MessageReactionRemoveEvent():
        _handleReactionRemove(event);
      case MessageReactionRemoveAllEvent():
        _handleReactionRemoveAll(event);
      case MessageReactionRemoveEmojiEvent():
        _handleReactionRemoveEmoji(event);
      case GuildCreateEvent():
        _handleGuildCreate(event);
      case GuildUpdateEvent():
        _handleGuildUpdate(event);
      case GuildDeleteEvent():
        _handleGuildDelete(event);
      case RelationshipAddEvent():
        _handleRelationshipUpsert(event.relationship);
      case RelationshipUpdateEvent():
        _handleRelationshipUpsert(event.relationship);
      case RelationshipRemoveEvent():
        _handleRelationshipRemove(event);
      case UserUpdateEvent():
        _handleUserUpdate(event);
      case MessageDeleteBulkEvent():
        _handleMessageDeleteBulk(event);
      case MessageAckEvent():
        _handleMessageAck(event);
      case MessageReactionAddManyEvent():
        _handleReactionAddMany(event);
      case ChannelUpdateBulkEvent():
        for (final channel in event.channels) {
          _handleChannelUpsert(channel);
        }
      case ChannelPinsUpdateEvent():
        talker.debug('[Gateway] CHANNEL_PINS_UPDATE: ${event.channelId}');
      case ChannelPinsAckEvent():
        talker.debug('[Gateway] CHANNEL_PINS_ACK: ${event.channelId}');
      case ChannelRecipientAddEvent():
        unawaited(database.userDao.upsertUser(userFromPartialSdk(event.user)));
      case ChannelRecipientRemoveEvent():
        talker.debug('[Gateway] CHANNEL_RECIPIENT_REMOVE: ${event.channelId}');
      case PassiveUpdatesEvent():
        _handlePassiveUpdates(event);
      case GuildRoleCreateEvent():
        _handleRoleUpsert(event.guildId, event.role);
      case GuildRoleUpdateEvent():
        _handleRoleUpsert(event.guildId, event.role);
      case GuildRoleDeleteEvent():
        unawaited(database.roleDao.deleteRole(event.roleId));
      case GuildRoleUpdateBulkEvent():
        _handleRoleUpdateBulk(event);
      case GuildBanAddEvent():
        talker.debug('[Gateway] GUILD_BAN_ADD: ${event.guildId}');
      case GuildBanRemoveEvent():
        talker.debug('[Gateway] GUILD_BAN_REMOVE: ${event.guildId}');
      case GuildEmojisUpdateEvent():
        talker.debug('[Gateway] GUILD_EMOJIS_UPDATE: ${event.guildId}');
      case GuildStickersUpdateEvent():
        talker.debug('[Gateway] GUILD_STICKERS_UPDATE: ${event.guildId}');
      case GuildSyncEvent():
        _handleGuildCreate(GuildCreateEvent(guild: event.guild));
      case GuildMembersChunkEvent():
        _handleMembersChunk(event);
      case GuildMemberListUpdateEvent():
        talker.debug('[Gateway] GUILD_MEMBER_LIST_UPDATE: ${event.guildId}');
      case PresenceUpdateBulkEvent():
        _handlePresenceUpdateBulk(event);
      case VoiceStateUpdateEvent():
        talker.debug('[Gateway] VOICE_STATE_UPDATE: ${event.state.userId}');
      case VoiceServerUpdateEvent():
        talker.debug('[Gateway] VOICE_SERVER_UPDATE');
      case CallCreateEvent():
        talker.debug('[Gateway] CALL_CREATE: ${event.channelId}');
      case CallUpdateEvent():
        talker.debug('[Gateway] CALL_UPDATE: ${event.channelId}');
      case CallDeleteEvent():
        talker.debug('[Gateway] CALL_DELETE: ${event.channelId}');
      case UserSettingsUpdateEvent():
        talker.debug('[Gateway] USER_SETTINGS_UPDATE');
      case UserGuildSettingsUpdateEvent():
        talker.debug('[Gateway] USER_GUILD_SETTINGS_UPDATE: ${event.guildId}');
      case UserPinnedDmsUpdateEvent():
        talker.debug('[Gateway] USER_PINNED_DMS_UPDATE');
      case UserNoteUpdateEvent():
        talker.debug('[Gateway] USER_NOTE_UPDATE: ${event.userId}');
      case UserConnectionsUpdateEvent():
        talker.debug('[Gateway] USER_CONNECTIONS_UPDATE');
      case AuthSessionChangeEvent():
        talker.debug('[Gateway] AUTH_SESSION_CHANGE');
      case InviteCreateEvent():
        talker.debug('[Gateway] INVITE_CREATE');
      case InviteDeleteEvent():
        talker.debug('[Gateway] INVITE_DELETE: ${event.code}');
      case SavedMessageCreateEvent():
        talker.debug('[Gateway] SAVED_MESSAGE_CREATE');
      case SavedMessageDeleteEvent():
        talker.debug('[Gateway] SAVED_MESSAGE_DELETE: ${event.messageId}');
      case RecentMentionDeleteEvent():
        talker.debug('[Gateway] RECENT_MENTION_DELETE: ${event.messageId}');
      case WebhooksUpdateEvent():
        talker.debug('[Gateway] WEBHOOKS_UPDATE: ${event.channelId}');
      case FavoriteMemeCreateEvent():
        talker.debug('[Gateway] FAVORITE_MEME_CREATE');
      case FavoriteMemeUpdateEvent():
        talker.debug('[Gateway] FAVORITE_MEME_UPDATE');
      case FavoriteMemeDeleteEvent():
        talker.debug('[Gateway] FAVORITE_MEME_DELETE: ${event.id}');
      case SessionsReplaceEvent():
        talker.debug('[Gateway] SESSIONS_REPLACE');
      case GatewayErrorEvent():
        talker.warning('[Gateway] Error: [${event.code}] ${event.message}');
      case UnknownGatewayEvent():
        talker.debug('[Gateway] Unknown event: ${event.eventType}');
    }
  }

  void _handleReady(ReadyEvent event) {
    talker.info('[Gateway] READY received (session: ${event.sessionId})');

    // Upsert current user.
    unawaited(
      database.userDao.upsertUser(
        db.UsersCompanion.insert(
          id: event.user.id,
          username: event.user.username,
          discriminator: Value(event.user.discriminator),
          globalName: Value(event.user.globalName),
          avatar: Value(event.user.avatar),
          avatarColor: Value(event.user.avatarColor),
          isBot: Value(event.user.bot ?? false),
        ),
      ),
    );

    // Upsert guilds.
    if (event.guilds.isNotEmpty) {
      final guildCompanions = <db.ServersCompanion>[];
      for (var i = 0; i < event.guilds.length; i++) {
        final g = event.guilds[i];
        guildCompanions.add(
          db.ServersCompanion.insert(
            id: g.id,
            name: g.name ?? '',
            icon: Value(g.icon),
            ownerId: Value(g.ownerId),
            position: Value(i),
          ),
        );
      }
      unawaited(database.guildDao.upsertServers(guildCompanions));
    }

    // Upsert DM channels.
    if (event.privateChannels.isNotEmpty) {
      final dmCompanions = <db.DmChannelsCompanion>[];
      for (final ch in event.privateChannels) {
        final recipients = ch.recipients;
        if (recipients == null || recipients.isEmpty) {
          continue;
        }
        for (final r in recipients) {
          unawaited(database.userDao.upsertUser(userFromPartialSdk(r)));
        }
        dmCompanions.add(
          db.DmChannelsCompanion.insert(
            id: ch.id,
            recipientId: recipients.first.id,
            type: Value(ch.type),
            name: Value(ch.name),
            recipientCount: Value(recipients.length + 1),
          ),
        );
      }
      unawaited(database.dmChannelDao.upsertDmChannels(dmCompanions));
    }

    // Upsert relationships.
    if (event.relationships.isNotEmpty) {
      final relCompanions = <db.RelationshipsCompanion>[];
      for (final rel in event.relationships) {
        unawaited(database.userDao.upsertUser(userFromPartialSdk(rel.user)));
        relCompanions.add(
          db.RelationshipsCompanion.insert(
            userId: rel.user.id,
            type: rel.type.json ?? 1,
            nickname: Value(rel.nickname),
            since: Value(rel.since),
          ),
        );
      }
      unawaited(database.relationshipDao.upsertRelationships(relCompanions));
    }

    // Upsert presences.
    for (final p in event.presences) {
      final userId = (p['user'] as Map<String, dynamic>?)?['id'] as String?;
      final status = p['status'] as String?;
      if (userId != null && status != null) {
        unawaited(
          database.userDao.upsertUser(
            db.UsersCompanion(id: Value(userId), status: Value(status)),
          ),
        );
      }
    }
  }

  void _handleMessageCreate(MessageCreateEvent event) {
    final msg = Message.fromSdk(event.message);

    // Upsert the author.
    unawaited(
      database.userDao.upsertUser(userFromPartialSdk(event.message.author)),
    );

    unawaited(database.messageDao.upsertMessage(msg.toCompanion()));

    // Update DM last-message metadata (no-ops for guild channels).
    unawaited(
      database.dmChannelDao.updateLastMessage(
        msg.channelId,
        msg.content,
        msg.authorId,
        msg.timestamp,
      ),
    );
  }

  void _handleMessageUpdate(MessageUpdateEvent event) {
    final msg = Message.fromSdk(event.message);
    unawaited(database.messageDao.upsertMessage(msg.toCompanion()));
  }

  void _handleMessageDelete(MessageDeleteEvent event) {
    unawaited(database.messageDao.deleteMessage(event.messageId));
  }

  void _handleTypingStart(TypingStartEvent event) {
    onTypingStart?.call(event.channelId, event.userId);
  }

  void _handlePresenceUpdate(PresenceUpdateEvent event) {
    unawaited(
      database.userDao.upsertUser(
        db.UsersCompanion(id: Value(event.userId), status: Value(event.status)),
      ),
    );
  }

  void _handleMemberUpsert(String guildId, GuildMemberResponse member) {
    unawaited(database.userDao.upsertUser(userFromPartialSdk(member.user)));

    unawaited(
      database.memberDao.upsertMember(
        db.MembersCompanion.insert(
          userId: member.user.id,
          serverId: guildId,
          nickname: Value(member.nick),
          serverAvatar: Value(member.avatar),
          roleIdsJson: Value(jsonEncode(member.roles)),
          joinedAt: Value(member.joinedAt),
        ),
      ),
    );
  }

  void _handleMemberRemove(GuildMemberRemoveEvent event) {
    unawaited(database.memberDao.deleteMember(event.userId, event.guildId));
  }

  void _handleChannelUpsert(ChannelResponse channel) {
    final guildId = channel.guildId;
    if (guildId == null) {
      return;
    }

    unawaited(
      database.channelDao.upsertChannel(channelFromSdk(channel, guildId)),
    );
  }

  void _handleChannelDelete(ChannelDeleteEvent event) {
    unawaited(database.channelDao.deleteChannel(event.channel.id));
  }

  void _handleUserUpdate(UserUpdateEvent event) {
    unawaited(
      database.userDao.upsertUser(
        db.UsersCompanion.insert(
          id: event.user.id,
          username: event.user.username,
          discriminator: Value(event.user.discriminator),
          globalName: Value(event.user.globalName),
          avatar: Value(event.user.avatar),
          avatarColor: Value(event.user.avatarColor),
          isBot: Value(event.user.bot ?? false),
        ),
      ),
    );
  }

  void _handleMessageDeleteBulk(MessageDeleteBulkEvent event) {
    for (final id in event.ids) {
      unawaited(database.messageDao.deleteMessage(id));
    }
  }

  void _handleRoleUpsert(String guildId, GuildRoleResponse role) {
    unawaited(database.roleDao.upsertRoles([roleFromSdk(role, guildId)]));
  }

  void _handleRoleUpdateBulk(GuildRoleUpdateBulkEvent event) {
    unawaited(
      database.roleDao.upsertRoles(
        event.roles.map((r) => roleFromSdk(r, event.guildId)).toList(),
      ),
    );
  }

  void _handleMembersChunk(GuildMembersChunkEvent event) {
    for (final member in event.members) {
      _handleMemberUpsert(event.guildId, member);
    }
  }

  void _handlePresenceUpdateBulk(PresenceUpdateBulkEvent event) {
    for (final p in event.presences) {
      final userId = (p['user'] as Map<String, dynamic>?)?['id'] as String?;
      final status = p['status'] as String?;
      if (userId != null && status != null) {
        unawaited(
          database.userDao.upsertUser(
            db.UsersCompanion(id: Value(userId), status: Value(status)),
          ),
        );
      }
    }
  }

  void _handleGuildCreate(GuildCreateEvent event) {
    unawaited(database.guildDao.upsertServer(guildFromSdk(event.guild.guild)));

    // Upsert channels and roles from the guild create payload.
    for (final channel in event.guild.channels) {
      final guildId = channel.guildId;
      if (guildId != null) {
        unawaited(
          database.channelDao.upsertChannel(channelFromSdk(channel, guildId)),
        );
      }
    }

    if (event.guild.roles.isNotEmpty) {
      unawaited(
        database.roleDao.upsertRoles(
          event.guild.roles
              .map((r) => roleFromSdk(r, event.guild.guild.id))
              .toList(),
        ),
      );
    }

    // Upsert members.
    for (final member in event.guild.members) {
      _handleMemberUpsert(event.guild.guild.id, member);
    }
  }

  void _handleGuildUpdate(GuildUpdateEvent event) {
    unawaited(database.guildDao.upsertServer(guildFromSdk(event.guild.guild)));
  }

  void _handleGuildDelete(GuildDeleteEvent event) {
    unawaited(database.channelDao.deleteChannelsForServer(event.guildId));
    unawaited(database.guildDao.deleteServer(event.guildId));
  }

  void _handleRelationshipUpsert(RelationshipResponse relationship) {
    unawaited(
      database.userDao.upsertUser(userFromPartialSdk(relationship.user)),
    );
    unawaited(
      database.relationshipDao.upsertRelationships([
        db.RelationshipsCompanion.insert(
          userId: relationship.user.id,
          type: relationship.type.json ?? 1,
          nickname: Value(relationship.nickname),
          since: Value(relationship.since),
        ),
      ]),
    );
  }

  void _handleRelationshipRemove(RelationshipRemoveEvent event) {
    unawaited(database.relationshipDao.deleteRelationship(event.userId));
  }

  void _handleReactionAdd(MessageReactionAddEvent event) {
    unawaited(_modifyReaction(event.messageId, event.emoji, isAdd: true));
  }

  void _handleReactionRemove(MessageReactionRemoveEvent event) {
    unawaited(_modifyReaction(event.messageId, event.emoji, isAdd: false));
  }

  void _handleReactionRemoveAll(MessageReactionRemoveAllEvent event) {
    unawaited(database.messageDao.updateReactions(event.messageId, '[]'));
  }

  void _handleReactionRemoveEmoji(MessageReactionRemoveEmojiEvent event) {
    unawaited(
      _removeEmojiReaction(event.messageId, event.emoji.name, event.emoji.id),
    );
  }

  Future<void> _modifyReaction(
    String messageId,
    ReactionEmoji emoji, {
    required bool isAdd,
  }) async {
    final msg = await database.messageDao.getMessage(messageId);
    if (msg == null) {
      return;
    }

    final reactions = _decodeReactions(msg.reactionsJson);
    final idx = reactions.indexWhere(
      (r) =>
          (r['emoji'] as String?) == emoji.name &&
          (r['emojiId'] as String?) == emoji.id,
    );

    if (isAdd) {
      if (idx != -1) {
        reactions[idx]['count'] = ((reactions[idx]['count'] as int?) ?? 0) + 1;
      } else {
        reactions.add(<String, dynamic>{
          'emoji': emoji.name,
          'emojiId': emoji.id,
          'animated': emoji.animated,
          'count': 1,
          'hasReacted': false,
        });
      }
    } else if (idx != -1) {
      final count = ((reactions[idx]['count'] as int?) ?? 1) - 1;
      if (count <= 0) {
        reactions.removeAt(idx);
      } else {
        reactions[idx]['count'] = count;
      }
    }

    await database.messageDao.updateReactions(messageId, jsonEncode(reactions));
  }

  Future<void> _removeEmojiReaction(
    String messageId,
    String emojiName,
    String? emojiId,
  ) async {
    final msg = await database.messageDao.getMessage(messageId);
    if (msg == null) {
      return;
    }

    final reactions = _decodeReactions(msg.reactionsJson)
      ..removeWhere(
        (r) =>
            (r['emoji'] as String?) == emojiName &&
            (r['emojiId'] as String?) == emojiId,
      );
    await database.messageDao.updateReactions(messageId, jsonEncode(reactions));
  }

  void _handleMessageAck(MessageAckEvent event) {
    unawaited(
      database.readStateDao.upsertReadState(
        db.ReadStatesCompanion(
          channelId: Value(event.channelId),
          lastMessageId: Value(event.messageId),
          mentionCount: Value(event.mentionCount ?? 0),
        ),
      ),
    );
  }

  void _handleReactionAddMany(MessageReactionAddManyEvent event) {
    for (final r in event.reactions) {
      final emoji = r['emoji'] as Map<String, dynamic>?;
      if (emoji == null) {
        continue;
      }
      unawaited(
        _modifyReaction(
          event.messageId,
          ReactionEmoji(
            name: emoji['name'] as String? ?? '',
            id: emoji['id'] as String?,
          ),
          isAdd: true,
        ),
      );
    }
  }

  void _handlePassiveUpdates(PassiveUpdatesEvent event) {
    // Handle channel creates.
    if (event.createdChannels != null) {
      for (final channel in event.createdChannels!) {
        _handleChannelUpsert(channel);
      }
    }

    // Handle channel updates.
    if (event.updatedChannels != null) {
      for (final channel in event.updatedChannels!) {
        _handleChannelUpsert(channel);
      }
    }

    // Handle channel deletes.
    if (event.deletedChannelIds != null) {
      for (final id in event.deletedChannelIds!) {
        unawaited(database.channelDao.deleteChannel(id));
      }
    }
  }

  List<Map<String, dynamic>> _decodeReactions(String json) {
    try {
      return (jsonDecode(json) as List<dynamic>).cast<Map<String, dynamic>>();
    } on Object {
      return [];
    }
  }
}
