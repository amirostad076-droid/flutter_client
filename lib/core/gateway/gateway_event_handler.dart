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
        guildCompanions.add(guildFromSdk(event.guilds[i], position: i));
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

  void _handleGuildCreate(GuildCreateEvent event) {
    unawaited(database.guildDao.upsertServer(guildFromSdk(event.guild)));
  }

  void _handleGuildUpdate(GuildUpdateEvent event) {
    unawaited(database.guildDao.upsertServer(guildFromSdk(event.guild)));
  }

  void _handleGuildDelete(GuildDeleteEvent event) {
    // GuildDao does not expose a delete method; clearing channels is sufficient
    // for now until a deleteServer method is added.
    unawaited(database.channelDao.deleteChannelsForServer(event.guildId));
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

  List<Map<String, dynamic>> _decodeReactions(String json) {
    try {
      return (jsonDecode(json) as List<dynamic>).cast<Map<String, dynamic>>();
    } on Object {
      return [];
    }
  }
}
