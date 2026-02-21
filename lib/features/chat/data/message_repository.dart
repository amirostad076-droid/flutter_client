import 'package:dio/dio.dart';
import 'package:fluxer_dart/fluxer_dart.dart';

import 'package:fluxeron/core/database/fluxer_database.dart' as db;
import 'package:fluxeron/features/chat/domain/message.dart';
import 'package:fluxeron/shared/utils/sdk_converters.dart';

class MessageRepository {
  final FluxerDart _client;
  final db.FluxerDatabase _db;

  const MessageRepository(this._client, this._db);

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
      final response = await _client.getMessagesApi().listMessages(
        channelId: channelId,
        limit: limit.toString(),
        before: before,
      );
      final data = response.data;
      if (data == null) {
        return [];
      }

      final messages = data.map(Message.fromSdk).toList().reversed.toList();

      // Upsert messages and their authors into Drift.
      for (final sdk in data) {
        await _db.userDao.upsertUser(userFromPartialSdk(sdk.author));
      }
      await _db.messageDao.upsertMessages(
        messages.map((m) => m.toCompanion()).toList(),
      );

      return messages;
    } on DioException catch (e) {
      throw Exception(e.response?.statusMessage ?? 'Failed to fetch messages');
    }
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

      final response = await _client.dio.post<Map<String, dynamic>>(
        '/channels/$channelId/messages',
        data: body,
      );
      final data = response.data;
      if (data == null) {
        throw Exception('Empty response from sendMessage');
      }

      final schema = _client.serializers.deserializeWith(
        MessageResponseSchema.serializer,
        data,
      );
      if (schema == null) {
        throw Exception('Failed to deserialize message response');
      }

      final message = Message.fromSdk(schema);
      await _db.messageDao.upsertMessage(message.toCompanion());
      return message;
    } on DioException catch (e) {
      throw Exception(e.response?.statusMessage ?? 'Failed to send message');
    }
  }
}
