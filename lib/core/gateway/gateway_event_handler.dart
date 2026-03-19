import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import 'package:fluxeron/core/database/fluxer_database.dart' as db;
import 'package:fluxeron/core/gateway/gateway_event.dart';

typedef TypingCallback = void Function(String channelId, String userId);

class GatewayEventHandler {
  GatewayEventHandler({required this.database, this.onTypingStart});

  final db.FluxerDatabase database;
  final TypingCallback? onTypingStart;

  void handle(GatewayEventType type, Map<String, dynamic> data) {
    switch (type) {
      case GatewayEventType.ready:
        _handleReady(data);
      case GatewayEventType.messageCreate:
        _handleMessageCreate(data);
      case GatewayEventType.messageUpdate:
        _handleMessageUpdate(data);
      case GatewayEventType.messageDelete:
        _handleMessageDelete(data);
      case GatewayEventType.typingStart:
        _handleTypingStart(data);
      case GatewayEventType.presenceUpdate:
        _handlePresenceUpdate(data);
      case GatewayEventType.guildMemberAdd:
      case GatewayEventType.guildMemberUpdate:
        _handleMemberUpsert(data);
      case GatewayEventType.guildMemberRemove:
        _handleMemberRemove(data);
      case GatewayEventType.channelCreate:
      case GatewayEventType.channelUpdate:
        _handleChannelUpsert(data);
      case GatewayEventType.channelDelete:
        _handleChannelDelete(data);
      case GatewayEventType.messageReactionAdd:
        _handleReactionAdd(data);
      case GatewayEventType.messageReactionRemove:
        _handleReactionRemove(data);
      case GatewayEventType.messageReactionRemoveAll:
        _handleReactionRemoveAll(data);
      case GatewayEventType.messageReactionRemoveEmoji:
        _handleReactionRemoveEmoji(data);
    }
  }

  void _handleReady(Map<String, dynamic> data) {
    debugPrint('[Gateway] READY received');
    final user = data['user'] as Map<String, dynamic>?;
    if (user != null) {
      _upsertUserFromJson(user);
    }
  }

  void _handleMessageCreate(Map<String, dynamic> data) {
    final author = data['author'] as Map<String, dynamic>?;
    if (author != null) {
      _upsertUserFromJson(author);
    }

    final companion = _messageCompanionFromJson(data);
    if (companion != null) {
      unawaited(database.messageDao.upsertMessage(companion));
    }

    final channelId = data['channel_id'] as String?;
    final authorId = author?['id'] as String?;
    final content = data['content'] as String?;
    final timestamp = data['timestamp'] as String?;
    if (channelId != null && authorId != null && timestamp != null) {
      unawaited(
        database.dmChannelDao.updateLastMessage(
          channelId,
          content ?? '',
          authorId,
          DateTime.parse(timestamp),
        ),
      );
    }
  }

  void _handleMessageUpdate(Map<String, dynamic> data) {
    final companion = _messageCompanionFromJson(data);
    if (companion != null) {
      unawaited(database.messageDao.upsertMessage(companion));
    }
  }

  void _handleMessageDelete(Map<String, dynamic> data) {
    final id = data['id'] as String?;
    if (id != null) {
      unawaited(database.messageDao.deleteMessage(id));
    }
  }

  void _handleTypingStart(Map<String, dynamic> data) {
    final channelId = data['channel_id'] as String?;
    final userId = data['user_id'] as String?;
    if (channelId != null && userId != null) {
      onTypingStart?.call(channelId, userId);
    }
  }

  void _handlePresenceUpdate(Map<String, dynamic> data) {
    final user = data['user'] as Map<String, dynamic>?;
    final status = data['status'] as String?;
    if (user == null || status == null) {
      return;
    }

    final userId = user['id'] as String?;
    if (userId == null) {
      return;
    }

    unawaited(
      database.userDao.upsertUser(
        db.UsersCompanion(id: Value(userId), status: Value(status)),
      ),
    );
  }

  void _handleMemberUpsert(Map<String, dynamic> data) {
    final user = data['user'] as Map<String, dynamic>?;
    final guildId = data['guild_id'] as String?;
    if (user == null || guildId == null) {
      return;
    }

    _upsertUserFromJson(user);

    final userId = user['id'] as String;
    final roles = (data['roles'] as List<dynamic>?)?.cast<String>() ?? [];

    unawaited(
      database.memberDao.upsertMember(
        db.MembersCompanion.insert(
          userId: userId,
          serverId: guildId,
          nickname: Value(data['nick'] as String?),
          serverAvatar: Value(data['avatar'] as String?),
          roleIdsJson: Value(jsonEncode(roles)),
          joinedAt: Value(
            data['joined_at'] != null
                ? DateTime.tryParse(data['joined_at'] as String)
                : null,
          ),
        ),
      ),
    );
  }

  void _handleMemberRemove(Map<String, dynamic> data) {
    final user = data['user'] as Map<String, dynamic>?;
    final guildId = data['guild_id'] as String?;
    if (user == null || guildId == null) {
      return;
    }

    final userId = user['id'] as String;
    unawaited(database.memberDao.deleteMember(userId, guildId));
  }

  void _handleChannelUpsert(Map<String, dynamic> data) {
    final id = data['id'] as String?;
    final guildId = data['guild_id'] as String?;
    if (id == null || guildId == null) {
      return;
    }

    unawaited(
      database.channelDao.upsertChannel(
        db.ChannelsCompanion.insert(
          id: id,
          serverId: guildId,
          name: (data['name'] as String?) ?? '',
          type: Value((data['type'] as int?) ?? 0),
          topic: Value(data['topic'] as String?),
          parentId: Value(data['parent_id'] as String?),
          position: Value((data['position'] as int?) ?? 0),
        ),
      ),
    );
  }

  void _handleChannelDelete(Map<String, dynamic> data) {
    final id = data['id'] as String?;
    if (id != null) {
      unawaited(database.channelDao.deleteChannel(id));
    }
  }

  void _handleReactionAdd(Map<String, dynamic> data) {
    final messageId = data['message_id'] as String?;
    final emoji = data['emoji'] as Map<String, dynamic>?;
    if (messageId == null || emoji == null) {
      return;
    }
    unawaited(_modifyReaction(messageId, emoji, isAdd: true));
  }

  void _handleReactionRemove(Map<String, dynamic> data) {
    final messageId = data['message_id'] as String?;
    final emoji = data['emoji'] as Map<String, dynamic>?;
    if (messageId == null || emoji == null) {
      return;
    }
    unawaited(_modifyReaction(messageId, emoji, isAdd: false));
  }

  void _handleReactionRemoveAll(Map<String, dynamic> data) {
    final messageId = data['message_id'] as String?;
    if (messageId == null) {
      return;
    }
    unawaited(database.messageDao.updateReactions(messageId, '[]'));
  }

  void _handleReactionRemoveEmoji(Map<String, dynamic> data) {
    final messageId = data['message_id'] as String?;
    final emoji = data['emoji'] as Map<String, dynamic>?;
    if (messageId == null || emoji == null) {
      return;
    }
    final emojiName = emoji['name'] as String? ?? '';
    final emojiId = emoji['id'] as String?;
    unawaited(_removeEmojiReaction(messageId, emojiName, emojiId));
  }

  Future<void> _modifyReaction(
    String messageId,
    Map<String, dynamic> emoji, {
    required bool isAdd,
  }) async {
    final msg = await database.messageDao.getMessage(messageId);
    if (msg == null) {
      return;
    }

    final emojiName = emoji['name'] as String? ?? '';
    final emojiId = emoji['id'] as String?;
    final animated = emoji['animated'] as bool? ?? false;

    final reactions = _decodeReactions(msg.reactionsJson);
    final idx = reactions.indexWhere(
      (r) =>
          (r['emoji'] as String?) == emojiName &&
          (r['emojiId'] as String?) == emojiId,
    );

    if (isAdd) {
      if (idx != -1) {
        reactions[idx]['count'] = ((reactions[idx]['count'] as int?) ?? 0) + 1;
      } else {
        reactions.add(<String, dynamic>{
          'emoji': emojiName,
          'emojiId': emojiId,
          'animated': animated,
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

  void _upsertUserFromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final username = json['username'] as String?;
    if (id == null || username == null) {
      return;
    }

    unawaited(
      database.userDao.upsertUser(
        db.UsersCompanion.insert(
          id: id,
          username: username,
          discriminator: Value((json['discriminator'] as String?) ?? '0'),
          globalName: Value(json['global_name'] as String?),
          avatar: Value(json['avatar'] as String?),
          avatarColor: Value(json['avatar_color'] as int?),
          isBot: Value((json['bot'] as bool?) ?? false),
        ),
      ),
    );
  }

  db.MessagesCompanion? _messageCompanionFromJson(Map<String, dynamic> data) {
    final id = data['id'] as String?;
    final channelId = data['channel_id'] as String?;
    final author = data['author'] as Map<String, dynamic>?;
    final content = data['content'] as String?;
    final timestamp = data['timestamp'] as String?;

    if (id == null ||
        channelId == null ||
        author == null ||
        timestamp == null) {
      return null;
    }

    return db.MessagesCompanion.insert(
      id: id,
      channelId: channelId,
      authorId: author['id'] as String,
      authorName: Value(
        (author['global_name'] as String?) ??
            (author['username'] as String?) ??
            '',
      ),
      authorAvatar: Value(author['avatar'] as String?),
      authorAvatarColor: Value(author['avatar_color'] as int?),
      content: content ?? '',
      timestamp: DateTime.parse(timestamp),
      embedsJson: Value(jsonEncode(data['embeds'] ?? [])),
      attachmentsJson: Value(jsonEncode(data['attachments'] ?? [])),
      reactionsJson: Value(jsonEncode(data['reactions'] ?? [])),
      replyToId: Value(
        (data['message_reference'] as Map<String, dynamic>?)?['message_id']
            as String?,
      ),
      type: Value((data['type'] as int?) ?? 0),
    );
  }
}
