import 'package:dio/dio.dart';
import 'package:fluxer_dart/export.dart';

import 'package:fluxeron/core/database/fluxer_database.dart' as db;
import 'package:fluxeron/core/talker.dart';
import 'package:fluxeron/features/chat/domain/message.dart';
import 'package:fluxeron/shared/utils/sdk_converters.dart';

class MessageRepository {
  final FluxerClient _client;
  final Dio _dio;
  final db.FluxerDatabase _db;

  const MessageRepository(this._client, this._dio, this._db);

  Stream<List<Message>> watchMessages(String channelId) {
    return _db.messageDao
        .watchMessages(channelId)
        .map((rows) => rows.map(Message.fromRow).toList());
  }

  Future<List<Message>> getMessages({
    required String channelId,
    int limit = 30,
    String? before,
  }) async {
    try {
      final data = await _client.channels.listMessages(
        channelId: channelId,
        limit: limit.toString(),
        before: before,
      );

      final messages = data.map(Message.fromSdk).toList().reversed.toList();

      for (final sdk in data) {
        await _db.userDao.upsertUser(userFromPartialSdk(sdk.author));
      }
      await _db.messageDao.upsertMessages(
        messages.map((m) => m.toCompanion()).toList(),
      );

      return messages;
    } on DioException catch (e) {
      // SDK deserialization can fail on a 200 response
      // (e.g. missing fields). Fall back to manual parsing.
      if (e.response?.statusCode == 200) {
        talker.warning(
          '[MessageRepo] SDK parse failed, '
          'using fallback: ${e.error}',
        );
        return _getMessagesFallback(
          channelId: channelId,
          limit: limit,
          before: before,
        );
      }
      throw Exception(
        e.error?.toString() ?? e.message ?? 'Failed to fetch messages',
      );
    }
  }

  /// Fallback: fetch raw JSON and parse manually,
  /// skipping individual messages that fail.
  Future<List<Message>> _getMessagesFallback({
    required String channelId,
    int limit = 30,
    String? before,
  }) async {
    final queryParams = <String, dynamic>{'limit': limit, 'before': ?before};
    final response = await _dio.get<List<dynamic>>(
      '/channels/$channelId/messages',
      queryParameters: queryParams,
    );
    final data = response.data;
    if (data == null) {
      return [];
    }

    final messages = <Message>[];
    for (final json in data.reversed) {
      try {
        final map = json as Map<String, dynamic>;
        final author = map['author'] as Map<String, dynamic>;
        messages.add(
          Message(
            id: map['id'] as String,
            channelId: map['channel_id'] as String,
            authorId: author['id'] as String,
            authorName:
                (author['global_name'] as String?) ??
                (author['username'] as String?) ??
                '',
            authorAvatar: author['avatar'] as String?,
            authorAvatarColor: author['avatar_color'] as int?,
            content: (map['content'] as String?) ?? '',
            timestamp: DateTime.parse(map['timestamp'] as String),
            editedTimestamp: map['edited_timestamp'] != null
                ? DateTime.tryParse(map['edited_timestamp'] as String)
                : null,
            embeds:
                (map['embeds'] as List<dynamic>?)
                    ?.map((e) => Embed.fromJson(e as Map<String, dynamic>))
                    .toList() ??
                const [],
            replyToId:
                (map['message_reference']
                        as Map<String, dynamic>?)?['message_id']
                    as String?,
            isPinned: (map['pinned'] as bool?) ?? false,
            isMentioned: (map['mention_everyone'] as bool?) ?? false,
            type: (map['type'] as int?) ?? 0,
          ),
        );

        await _db.userDao.upsertUser(
          db.UsersCompanion.insert(
            id: author['id'] as String,
            username: (author['username'] as String?) ?? '',
          ),
        );
      } on Object catch (e) {
        talker.warning('[MessageRepo] Skipping message: $e');
      }
    }

    if (messages.isNotEmpty) {
      await _db.messageDao.upsertMessages(
        messages.map((m) => m.toCompanion()).toList(),
      );
    }

    return messages;
  }

  Future<void> addReaction({
    required String channelId,
    required String messageId,
    required String emoji,
  }) async {
    await _client.channels.addReaction(
      channelId: channelId,
      messageId: messageId,
      emoji: emoji,
    );
  }

  Future<void> removeReaction({
    required String channelId,
    required String messageId,
    required String emoji,
  }) async {
    await _client.channels.removeOwnReaction(
      channelId: channelId,
      messageId: messageId,
      emoji: emoji,
    );
  }

  Future<Message> sendMessage({
    required String channelId,
    required String content,
    String? replyToId,
  }) async {
    try {
      final body = <String, dynamic>{'content': content};
      if (replyToId != null) {
        body['message_reference'] = <String, dynamic>{'message_id': replyToId};
      }

      final response = await _dio.post<Map<String, dynamic>>(
        '/channels/$channelId/messages',
        data: body,
      );
      final data = response.data;
      if (data == null) {
        throw Exception('Empty response from sendMessage');
      }

      final schema = MessageResponseSchema.fromJson(data);

      final message = Message.fromSdk(schema);
      await _db.messageDao.upsertMessage(message.toCompanion());
      return message;
    } on DioException catch (e) {
      throw Exception(e.response?.statusMessage ?? 'Failed to send message');
    }
  }
}
