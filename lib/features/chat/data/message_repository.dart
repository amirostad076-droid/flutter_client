import 'dart:convert';

import 'package:cross_file/cross_file.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/core/talker.dart';
import 'package:fluxer_app/features/channels/data/read_state_repository.dart';
import 'package:fluxer_app/features/chat/domain/api_attachment_metadata.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/shared/utils/sdk_converters.dart';
import 'package:fluxer_app/shared/utils/snowflake_time.dart';
import 'package:fluxer_dart/export.dart';

const int kMessageFlagCompactAttachments = 1 << 17;

Map<String, dynamic> buildMessageCreateBody({
  required String content,
  String? replyToId,
  String? clientNonce,
  List<String> stickerIds = const [],
  String? favoriteMemeId,
  List<ApiAttachmentMetadata>? attachments,
}) {
  final body = <String, dynamic>{};
  if (content.isNotEmpty) {
    body['content'] = content;
  }
  if (replyToId != null) {
    body['message_reference'] = <String, dynamic>{'message_id': replyToId};
    body['allowed_mentions'] = <String, dynamic>{'replied_user': true};
  }
  if (stickerIds.isNotEmpty) {
    body['sticker_ids'] = stickerIds;
  }
  if (favoriteMemeId != null) {
    body['favorite_meme_id'] = favoriteMemeId;
    body['flags'] = kMessageFlagCompactAttachments;
  }
  if (attachments != null && attachments.isNotEmpty) {
    body['attachments'] = attachments
        .map((ApiAttachmentMetadata e) => e.toJson())
        .toList();
  }
  if (clientNonce != null && clientNonce.isNotEmpty) {
    body['nonce'] = clientNonce;
  }
  return body;
}

class MessageRepository {
  final FluxerClient _client;
  final Dio _dio;
  final db.FluxerDatabase _db;
  final String? _currentUserId;

  const MessageRepository(
    this._client,
    this._dio,
    this._db,
    this._currentUserId,
  );

  Stream<List<Message>> watchMessages(String channelId) {
    return _db.messageDao
        .watchMessages(channelId)
        .map((rows) => rows.map(Message.fromRow).toList());
  }

  Future<List<Message>> getMessages({
    required String channelId,
    int limit = 30,
    String? before,
    String? after,
    String? around,
  }) async {
    try {
      final data = await _client.channels.listMessages(
        channelId: channelId,
        limit: limit.toString(),
        before: before,
        after: after,
        around: around,
      );

      final messages = data
          .map((sdk) => Message.fromSdk(sdk, currentUserId: _currentUserId))
          .toList()
          .reversed
          .toList();

      for (final sdk in data) {
        await _db.userDao.upsertUser(userFromPartialSdk(sdk.author));
      }
      await _db.messageDao.upsertMessages(
        messages.map((m) => m.toCompanion()).toList(),
      );

      if (messages.isNotEmpty) {
        final last = messages.last;
        await _db.dmChannelDao.updateLastMessage(
          channelId,
          last.id,
          last.content,
          last.authorId,
          last.timestamp,
        );
      }

      if (messages.any((m) => m.isMentioned)) {
        await ReadStateRepository(
          _client,
          _db,
        ).recomputeMentionsAfterBackfill(
          channelId: channelId,
          currentUserId: _currentUserId,
        );
      }

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
          after: after,
          around: around,
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
    String? after,
    String? around,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'before': ?before,
      'after': ?after,
      'around': ?around,
    };
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
            authorIsBot: (author['bot'] as bool?) ?? false,
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
            attachments:
                (map['attachments'] as List<dynamic>?)
                    ?.map((e) => Attachment.fromJson(e as Map<String, dynamic>))
                    .toList() ??
                const [],
            stickers:
                (map['stickers'] as List<dynamic>?)
                    ?.map(
                      (e) => MessageSticker.fromJson(e as Map<String, dynamic>),
                    )
                    .toList() ??
                const [],
            replyToId:
                (map['message_reference']
                        as Map<String, dynamic>?)?['message_id']
                    as String?,
            messageReference: map['message_reference'] != null
                ? MessageReference.fromJson(
                    map['message_reference'] as Map<String, dynamic>,
                  )
                : null,
            messageSnapshots:
                (map['message_snapshots'] as List<dynamic>?)
                    ?.map(
                      (e) =>
                          MessageSnapshot.fromJson(e as Map<String, dynamic>),
                    )
                    .toList() ??
                const [],
            isPinned: (map['pinned'] as bool?) ?? false,
            isMentioned: _isMentionedFromJson(map),
            type: (map['type'] as int?) ?? 0,
            flags: (map['flags'] as int?) ?? 0,
          ),
        );

        final authorId = author['id'] as String;
        await _db.userDao.upsertUser(
          db.UsersCompanion.insert(
            id: authorId,
            username: (author['username'] as String?) ?? '',
            memberSince: Value(dateTimeFromUserSnowflakeOrNull(authorId)),
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

      final last = messages.last;
      await _db.dmChannelDao.updateLastMessage(
        channelId,
        last.id,
        last.content,
        last.authorId,
        last.timestamp,
      );
    }

    if (messages.any((m) => m.isMentioned)) {
      await ReadStateRepository(
        _client,
        _db,
      ).recomputeMentionsAfterBackfill(
        channelId: channelId,
        currentUserId: _currentUserId,
      );
    }

    return messages;
  }

  bool _isMentionedFromJson(Map<String, dynamic> map) {
    if ((map['mention_everyone'] as bool?) ?? false) {
      return true;
    }
    if (_currentUserId == null) {
      return false;
    }
    final mentions = map['mentions'] as List<dynamic>?;
    if (mentions != null) {
      for (final m in mentions) {
        if (m is Map<String, dynamic> && m['id'] == _currentUserId) {
          return true;
        }
      }
    }
    return false;
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
    String? clientNonce,
    List<String> stickerIds = const [],
    String? favoriteMemeId,
    List<ApiAttachmentMetadata>? attachmentMetadata,
    List<XFile>? attachmentFiles,
  }) async {
    try {
      final Map<String, dynamic> body = buildMessageCreateBody(
        content: content,
        replyToId: replyToId,
        clientNonce: clientNonce,
        stickerIds: stickerIds,
        favoriteMemeId: favoriteMemeId,
        attachments: attachmentMetadata,
      );

      if (attachmentFiles != null && attachmentFiles.isNotEmpty) {
        final FormData formData = FormData();
        formData.fields.add(MapEntry('payload_json', jsonEncode(body)));
        for (var i = 0; i < attachmentFiles.length; i++) {
          final XFile x = attachmentFiles[i];
          formData.files.add(
            MapEntry(
              'files[$i]',
              await MultipartFile.fromFile(x.path, filename: x.name),
            ),
          );
        }
        final Response<Map<String, dynamic>> response = await _dio
            .post<Map<String, dynamic>>(
              '/channels/$channelId/messages',
              data: formData,
              options: Options(
                contentType: 'multipart/form-data',
                sendTimeout: const Duration(minutes: 30),
                receiveTimeout: const Duration(minutes: 5),
              ),
            );
        final Map<String, dynamic>? data = response.data;
        if (data == null) {
          throw Exception('Empty response from sendMessage');
        }
        final MessageResponseSchema schema = MessageResponseSchema.fromJson(
          data,
        );
        final Message message = Message.fromSdk(
          schema,
          currentUserId: _currentUserId,
        );
        await _db.messageDao.upsertMessage(message.toCompanion());
        return message;
      }

      final Response<Map<String, dynamic>> response = await _dio
          .post<Map<String, dynamic>>(
            '/channels/$channelId/messages',
            data: body,
            options: Options(
              sendTimeout: const Duration(minutes: 5),
              receiveTimeout: const Duration(minutes: 2),
            ),
          );
      final Map<String, dynamic>? data = response.data;
      if (data == null) {
        throw Exception('Empty response from sendMessage');
      }

      final MessageResponseSchema schema = MessageResponseSchema.fromJson(data);

      final Message message = Message.fromSdk(
        schema,
        currentUserId: _currentUserId,
      );
      await _db.messageDao.upsertMessage(message.toCompanion());
      return message;
    } on DioException catch (e) {
      throw Exception(e.response?.statusMessage ?? 'Failed to send message');
    }
  }

  Future<Message> editMessage({
    required String channelId,
    required String messageId,
    required String content,
  }) async {
    try {
      final MessageResponseSchema schema = await _client.channels.editMessage(
        channelId: channelId,
        messageId: messageId,
        content: content,
      );
      final Message message = Message.fromSdk(
        schema,
        currentUserId: _currentUserId,
      );
      await _db.messageDao.upsertMessage(message.toCompanion());
      return message;
    } on DioException catch (e) {
      throw Exception(e.response?.statusMessage ?? 'Failed to edit message');
    }
  }
}
