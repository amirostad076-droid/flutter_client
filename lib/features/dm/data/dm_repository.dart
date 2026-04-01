import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/features/dm/domain/dm_conversation.dart';
import 'package:fluxer_app/shared/utils/sdk_converters.dart';
import 'package:fluxer_app/shared/utils/snowflake_time.dart';
import 'package:fluxer_dart/export.dart';

class DmRepository {
  final FluxerClient _client;
  final db.FluxerDatabase _db;

  const DmRepository(this._client, this._db);

  Stream<List<DmConversation>> watchDmChannels() {
    return _db.dmChannelDao.watchDmChannels().asyncMap((rows) async {
      final userIds = <String>{
        ...rows.map((r) => r.recipientId),
        ...rows.map((r) => r.lastMessageAuthorId).whereType<String>(),
      };
      final users = await _db.userDao.getUsersByIds(userIds.toList());
      final userMap = {for (final u in users) u.id: u};

      return rows
          .map(
            (row) => DmConversation.fromRow(
              row,
              userMap[row.recipientId],
              lastMessageAuthor: row.lastMessageAuthorId != null
                  ? userMap[row.lastMessageAuthorId]
                  : null,
            ),
          )
          .toList();
    });
  }

  Future<List<DmConversation>> getDmChannels() async {
    try {
      final channels = await _client.users.listPrivateChannels();

      final companions = <db.DmChannelsCompanion>[];
      for (final ch in channels) {
        if (ch.type != 1 && ch.type != 3) {
          continue;
        }
        final recipients = ch.recipients;
        if (recipients == null || recipients.isEmpty) {
          continue;
        }

        for (final r in recipients) {
          await _db.userDao.upsertUser(userFromPartialSdk(r));
        }

        companions.add(
          db.DmChannelsCompanion.insert(
            id: ch.id,
            recipientId: recipients.first.id,
            type: Value(ch.type),
            name: Value(ch.name),
            recipientCount: Value(recipients.length + 1),
            lastMessage: const Value(''),
            lastMessageTime: Value(
              ch.lastMessageId != null
                  ? dateTimeFromSnowflakeAsLocalOrNow(ch.lastMessageId!)
                  : dateTimeFromSnowflakeAsLocalOrNow(ch.id),
            ),
          ),
        );
      }

      await _db.dmChannelDao.upsertDmChannels(companions);

      final rows = await _db.dmChannelDao.getDmChannels();
      final userIds = <String>{
        ...rows.map((r) => r.recipientId),
        ...rows.map((r) => r.lastMessageAuthorId).whereType<String>(),
      };
      final users = await _db.userDao.getUsersByIds(userIds.toList());
      final userMap = {for (final u in users) u.id: u};

      return rows
          .map(
            (row) => DmConversation.fromRow(
              row,
              userMap[row.recipientId],
              lastMessageAuthor: row.lastMessageAuthorId != null
                  ? userMap[row.lastMessageAuthorId]
                  : null,
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.statusMessage ?? 'Failed to fetch DM channels',
      );
    }
  }

  Future<void> markAsRead(String channelId) async {
    await _db.dmChannelDao.markAsRead(channelId);

    // Find the latest message to ack: prefer cached messages, fall back
    // to the read state's ack point.
    final messages = await _db.messageDao.getMessages(channelId, limit: 1);
    final messageId = messages.isNotEmpty
        ? messages.last.id
        : (await _db.readStateDao.getReadState(channelId))?.lastMessageId;
    if (messageId != null) {
      await _client.channels.acknowledgeMessage(
        channelId: channelId,
        messageId: messageId,
        body: const MessageAckRequest(),
      );
    }
  }

  Future<void> closeDmChannel(String channelId) async {
    await _client.channels.deleteChannel(channelId: channelId);
    await _db.dmChannelDao.deleteDmChannel(channelId);
  }

  Future<void> pinDm(String channelId) async {
    await _client.users.pinDirectMessageChannel(channelId: channelId);
  }

  Future<void> unpinDm(String channelId) async {
    await _client.users.unpinDirectMessageChannel(channelId: channelId);
  }

  Future<void> muteDm(String channelId, {int? durationSeconds}) async {
    String? endTime;
    final selectedTimeWindow = durationSeconds ?? -1;
    if (durationSeconds != null) {
      endTime = DateTime.now()
          .add(Duration(seconds: durationSeconds))
          .toUtc()
          .toIso8601String();
    }

    await _client.users.updateDmNotificationSettings(
      body: UserGuildSettingsUpdateRequest(
        channelOverrides: {
          channelId: ChannelOverrides(
            collapsed: false,
            messageNotifications: UserNotificationSettings.inherit,
            muted: true,
            muteConfig: ChannelOverridesMuteConfig(
              endTime: endTime,
              selectedTimeWindow: selectedTimeWindow,
            ),
          ),
        },
      ),
    );
  }

  Future<void> unmuteDm(String channelId) async {
    await _client.users.updateDmNotificationSettings(
      body: UserGuildSettingsUpdateRequest(
        channelOverrides: {
          channelId: const ChannelOverrides(
            collapsed: false,
            messageNotifications: UserNotificationSettings.inherit,
            muted: false,
            muteConfig: null,
          ),
        },
      ),
    );
  }
}
