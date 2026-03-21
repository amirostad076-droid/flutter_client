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

  /// The current user's ID, set during READY processing.
  String? _currentUserId;

  Future<void> handle(GatewayEvent event) async {
    switch (event) {
      case ReadyEvent():
        await _handleReady(event);
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
        unawaited(_handleUserSettingsUpdate(event));
      case UserGuildSettingsUpdateEvent():
        unawaited(_handleUserGuildSettingsUpdate(event));
      case UserPinnedDmsUpdateEvent():
        unawaited(_handleUserPinnedDmsUpdate(event));
      case UserNoteUpdateEvent():
        unawaited(_handleUserNoteUpdate(event));
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
        unawaited(_handleFavoriteMemeCreate(event));
      case FavoriteMemeUpdateEvent():
        unawaited(_handleFavoriteMemeUpdate(event));
      case FavoriteMemeDeleteEvent():
        unawaited(_handleFavoriteMemeDelete(event));
      case SessionsReplaceEvent():
        talker.debug('[Gateway] SESSIONS_REPLACE');
      case GatewayErrorEvent():
        talker.warning('[Gateway] Error: [${event.code}] ${event.message}');
      case UnknownGatewayEvent():
        talker.debug('[Gateway] Unknown event: ${event.eventType}');
    }
  }

  Future<void> _handleReady(ReadyEvent event) async {
    talker.info('[Gateway] READY received (session: ${event.sessionId})');

    _currentUserId = event.user.id;

    await database.transaction(() async {
      // Clear all entity tables (full replace).
      await database.userDao.clearAll();
      await database.guildDao.clearAll();
      await database.channelDao.clearAll();
      await database.dmChannelDao.clearAll();
      await database.memberDao.clearAll();
      await database.roleDao.clearAll();
      await database.relationshipDao.clearAll();
      await database.readStateDao.clearAll();
      await database.userSettingsDao.clearAll();
      await database.userGuildSettingsDao.clearAll();
      await database.userNotesDao.clearAll();
      await database.pinnedDmsDao.clearAll();
      await database.favoriteMemesDao.clearAll();
      await database.rtcRegionsDao.clearAll();

      // Insert current user.
      await database.userDao.upsertUser(
        db.UsersCompanion.insert(
          id: event.user.id,
          username: event.user.username,
          discriminator: Value(event.user.discriminator),
          globalName: Value(event.user.globalName),
          avatar: Value(event.user.avatar),
          avatarColor: Value(event.user.avatarColor),
          isBot: Value(event.user.bot ?? false),
        ),
      );

      // Insert cached users.
      final cachedUsers = event.users;
      if (cachedUsers != null && cachedUsers.isNotEmpty) {
        await database.userDao.upsertUsers(
          cachedUsers
              .map(
                (u) => userFromPartialSdk(
                  UserPartialResponse.fromJson(u.cast<String, Object?>()),
                ),
              )
              .toList(),
        );
      }

      // Insert guilds with position index.
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
        await database.guildDao.upsertServers(guildCompanions);
      }

      // Insert DM channels (+ upsert recipients as users).
      if (event.privateChannels.isNotEmpty) {
        final dmCompanions = <db.DmChannelsCompanion>[];
        final recipientUsers = <db.UsersCompanion>[];
        for (final ch in event.privateChannels) {
          final recipients = ch.recipients;
          if (recipients == null || recipients.isEmpty) {
            continue;
          }
          for (final r in recipients) {
            recipientUsers.add(userFromPartialSdk(r));
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
        if (recipientUsers.isNotEmpty) {
          await database.userDao.upsertUsers(recipientUsers);
        }
        await database.dmChannelDao.upsertDmChannels(dmCompanions);
      }

      // Insert relationships (+ upsert related users).
      if (event.relationships.isNotEmpty) {
        final relUsers = <db.UsersCompanion>[];
        final relCompanions = <db.RelationshipsCompanion>[];
        for (final rel in event.relationships) {
          relUsers.add(userFromPartialSdk(rel.user));
          relCompanions.add(
            db.RelationshipsCompanion.insert(
              userId: rel.user.id,
              type: rel.type.json ?? 1,
              nickname: Value(rel.nickname),
              since: Value(rel.since),
            ),
          );
        }
        await database.userDao.upsertUsers(relUsers);
        await database.relationshipDao.upsertRelationships(relCompanions);
      }

      // Update user statuses from presences.
      for (final p in event.presences) {
        final userId = (p['user'] as Map<String, dynamic>?)?['id'] as String?;
        final status = p['status'] as String?;
        if (userId != null && status != null) {
          await database.userDao.upsertUser(
            db.UsersCompanion(id: Value(userId), status: Value(status)),
          );
        }
      }

      // Insert read states.
      if (event.readStates.isNotEmpty) {
        for (final rs in event.readStates) {
          await database.readStateDao.upsertReadState(
            db.ReadStatesCompanion(
              channelId: Value(rs.id),
              lastMessageId: Value(rs.lastMessageId),
              mentionCount: Value(rs.mentionCount),
            ),
          );
        }
      }

      // Insert user settings (JSON blob).
      final userSettings = event.userSettings;
      if (userSettings != null) {
        await database.userSettingsDao.upsertSettings(
          db.UserSettingsTableCompanion(
            userId: Value(event.user.id),
            data: Value(jsonEncode(userSettings.toJson())),
          ),
        );
      }

      // Insert user guild settings (JSON blob per guild).
      final guildSettings = event.userGuildSettings;
      if (guildSettings != null) {
        for (final gs in guildSettings) {
          final guildId = gs.guildId;
          if (guildId == null) {
            continue;
          }
          await database.userGuildSettingsDao.upsert(
            db.UserGuildSettingsTableCompanion(
              guildId: Value(guildId),
              data: Value(jsonEncode(gs.toJson())),
            ),
          );
        }
      }

      // Insert notes.
      final notes = event.notes;
      if (notes != null && notes.isNotEmpty) {
        await database.userNotesDao.upsertNotes(
          notes.entries
              .map(
                (e) => db.UserNotesTableCompanion(
                  targetUserId: Value(e.key),
                  content: Value(e.value),
                ),
              )
              .toList(),
        );
      }

      // Insert pinned DMs with position index (table already cleared above).
      final pinnedDms = event.pinnedDms;
      if (pinnedDms != null && pinnedDms.isNotEmpty) {
        for (var i = 0; i < pinnedDms.length; i++) {
          await database
              .into(database.pinnedDmsTable)
              .insert(
                db.PinnedDmsTableCompanion(
                  channelId: Value(pinnedDms[i]),
                  position: Value(i),
                ),
              );
        }
      }

      // Insert favorite memes (JSON blob per meme).
      final favoriteMemes = event.favoriteMemes;
      if (favoriteMemes != null) {
        for (final meme in favoriteMemes) {
          final id = meme['id'] as String?;
          if (id == null) {
            continue;
          }
          await database.favoriteMemesDao.upsert(
            db.FavoriteMemesTableCompanion(
              id: Value(id),
              data: Value(jsonEncode(meme)),
            ),
          );
        }
      }

      // Insert RTC regions (table already cleared above).
      final rtcRegions = event.rtcRegions;
      if (rtcRegions != null) {
        for (final region in rtcRegions) {
          final id = region['id'] as String?;
          if (id == null) {
            continue;
          }
          await database
              .into(database.rtcRegionsTable)
              .insert(
                db.RtcRegionsTableCompanion(
                  id: Value(id),
                  data: Value(jsonEncode(region)),
                ),
              );
        }
      }
    });
  }

  Future<void> _handleUserSettingsUpdate(UserSettingsUpdateEvent event) async {
    final userId = _currentUserId;
    if (userId == null) {
      return;
    }
    await database.userSettingsDao.upsertSettings(
      db.UserSettingsTableCompanion(
        userId: Value(userId),
        data: Value(jsonEncode(event.settings.toJson())),
      ),
    );
  }

  Future<void> _handleUserGuildSettingsUpdate(
    UserGuildSettingsUpdateEvent event,
  ) async {
    await database.userGuildSettingsDao.upsert(
      db.UserGuildSettingsTableCompanion(
        guildId: Value(event.guildId),
        data: Value(jsonEncode(event.data)),
      ),
    );
  }

  Future<void> _handleUserNoteUpdate(UserNoteUpdateEvent event) async {
    if (event.note == null || event.note!.isEmpty) {
      await database.userNotesDao.deleteNote(event.userId);
    } else {
      await database.userNotesDao.upsertNote(
        db.UserNotesTableCompanion(
          targetUserId: Value(event.userId),
          content: Value(event.note!),
        ),
      );
    }
  }

  Future<void> _handleUserPinnedDmsUpdate(
    UserPinnedDmsUpdateEvent event,
  ) async {
    final companions = <db.PinnedDmsTableCompanion>[];
    for (var i = 0; i < event.pinnedDmChannelIds.length; i++) {
      companions.add(
        db.PinnedDmsTableCompanion(
          channelId: Value(event.pinnedDmChannelIds[i]),
          position: Value(i),
        ),
      );
    }
    await database.pinnedDmsDao.replaceAll(companions);
  }

  Future<void> _handleFavoriteMemeCreate(FavoriteMemeCreateEvent event) async {
    final id = event.data['id'] as String? ?? '';
    if (id.isNotEmpty) {
      await database.favoriteMemesDao.upsert(
        db.FavoriteMemesTableCompanion(
          id: Value(id),
          data: Value(jsonEncode(event.data)),
        ),
      );
    }
  }

  Future<void> _handleFavoriteMemeUpdate(FavoriteMemeUpdateEvent event) async {
    final id = event.data['id'] as String? ?? '';
    if (id.isNotEmpty) {
      await database.favoriteMemesDao.upsert(
        db.FavoriteMemesTableCompanion(
          id: Value(id),
          data: Value(jsonEncode(event.data)),
        ),
      );
    }
  }

  Future<void> _handleFavoriteMemeDelete(FavoriteMemeDeleteEvent event) async {
    await database.favoriteMemesDao.deleteMeme(event.id);
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
