import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:fluxer_dart/fluxer_dart.dart';

import 'package:fluxeron/core/database/fluxer_database.dart' as db;
import 'package:fluxeron/features/dm/domain/dm_conversation.dart';
import 'package:fluxeron/shared/utils/sdk_converters.dart';

/// Discord epoch (2015-01-01T00:00:00Z) in milliseconds.
const _kDiscordEpoch = 1420070400000;

/// Extracts a [DateTime] from a Discord/Fluxer snowflake ID.
DateTime _snowflakeToDateTime(String snowflake) {
  final id = int.tryParse(snowflake);
  if (id == null) {
    return DateTime.now();
  }
  return DateTime.fromMillisecondsSinceEpoch((id >> 22) + _kDiscordEpoch);
}

class DmRepository {
  final FluxerDart _client;
  final db.FluxerDatabase _db;

  const DmRepository(this._client, this._db);

  Stream<List<DmConversation>> watchDmChannels() {
    return _db.dmChannelDao.watchDmChannels().asyncMap((rows) async {
      final userIds = rows.map((r) => r.recipientId).toList();
      final users = await _db.userDao.getUsersByIds(userIds);
      final userMap = {for (final u in users) u.id: u};

      return rows
          .map((row) => DmConversation.fromRow(row, userMap[row.recipientId]))
          .toList();
    });
  }

  Future<List<DmConversation>> getDmChannels() async {
    try {
      final response = await _client.getUsersApi().listPrivateChannels();
      final data = response.data;
      if (data == null) {
        return [];
      }

      final companions = <db.DmChannelsCompanion>[];
      for (final ch in data) {
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
                  ? _snowflakeToDateTime(ch.lastMessageId!)
                  : DateTime.now(),
            ),
          ),
        );
      }

      await _db.dmChannelDao.upsertDmChannels(companions);

      final rows = await _db.dmChannelDao.getDmChannels();
      final userIds = rows.map((r) => r.recipientId).toList();
      final users = await _db.userDao.getUsersByIds(userIds);
      final userMap = {for (final u in users) u.id: u};

      return rows
          .map((row) => DmConversation.fromRow(row, userMap[row.recipientId]))
          .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.statusMessage ?? 'Failed to fetch DM channels',
      );
    }
  }
}
