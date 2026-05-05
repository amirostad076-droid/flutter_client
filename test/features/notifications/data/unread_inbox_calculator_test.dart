import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/features/notifications/data/unread_inbox_calculator.dart';
import 'package:fluxer_app/features/notifications/domain/unread_inbox_entry.dart';
import 'package:fluxer_app/shared/utils/snowflake_time.dart';

String _snowflakeForUtc(DateTime utc) {
  final int ms = utc.millisecondsSinceEpoch;
  final int internal = (ms - kSnowflakeEpochMs) << 22;
  return internal.toString();
}

void main() {
  test(
    'guild channel with last message and no read state row appears as unread',
    () async {
      final FluxerDatabase db = FluxerDatabase.forTesting(
        NativeDatabase.memory(),
      );
      addTearDown(db.close);

      const String guildId = 'guild_test_1';
      const String channelId = 'channel_test_1';
      const String userId = 'user_test_1';

      await db.guildDao.upsertServer(
        ServersCompanion.insert(id: guildId, name: 'Test Guild'),
      );
      await db.channelDao.upsertChannel(
        ChannelsCompanion.insert(
          id: channelId,
          guildId: guildId,
          name: 'general',
          lastMessageId: Value(_snowflakeForUtc(DateTime.utc(2026, 5))),
        ),
      );
      await db.memberDao.upsertMember(
        MembersCompanion.insert(
          userId: userId,
          guildId: guildId,
          joinedAt: Value(DateTime.utc(2020, 1, 15)),
        ),
      );

      final List<UnreadInboxEntry> entries =
          await UnreadInboxCalculator.compute(
            db,
            collapsedByChannelId: <String, bool>{},
            currentUserId: userId,
          );

      expect(entries, hasLength(1));
      expect(entries.single.channelId, channelId);
      expect(entries.single.isDm, isFalse);
    },
  );
}
