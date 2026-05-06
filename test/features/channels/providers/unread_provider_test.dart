import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/features/channels/providers/unread_provider.dart';
import 'package:fluxer_app/shared/utils/snowflake_time.dart';

String _snowflakeForUtc(DateTime utc) {
  final int internal = (utc.millisecondsSinceEpoch - kSnowflakeEpochMs) << 22;
  return internal.toString();
}

void main() {
  test(
    'channelUnread uses channel last message when no messages are cached',
    () async {
      final db = FluxerDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final channelId = _snowflakeForUtc(DateTime.utc(2026, 5));
      final lastMessageId = _snowflakeForUtc(DateTime.utc(2026, 5, 6));
      await db.channelDao.upsertChannel(
        ChannelsCompanion.insert(
          id: channelId,
          guildId: 'guild-1',
          name: 'general',
          lastMessageId: Value(lastMessageId),
        ),
      );

      final container = _container(db);
      addTearDown(container.dispose);

      final subscription = container.listen(
        channelUnreadProvider(channelId),
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      final unread = await container.read(
        channelUnreadProvider(channelId).future,
      );

      expect(unread.hasUnread, isTrue);
      expect(unread.mentionCount, 0);
    },
  );

  test(
    'channelUnread reports unread pins when channel pins are newer',
    () async {
      final db = FluxerDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      const latestPin = '2026-05-06T12:00:00.000Z';
      const ackedPin = '2026-05-05T12:00:00.000Z';
      await db.channelDao.upsertChannel(
        ChannelsCompanion.insert(
          id: 'channel-1',
          guildId: 'guild-1',
          name: 'general',
          lastPinTimestamp: const Value(latestPin),
        ),
      );
      await db.readStateDao.upsertReadState(
        const ReadStatesCompanion(
          channelId: Value('channel-1'),
          lastPinTimestamp: Value(ackedPin),
        ),
      );

      final container = _container(db);
      addTearDown(container.dispose);
      final subscription = container.listen(
        channelUnreadProvider('channel-1'),
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      final unread = await container.read(
        channelUnreadProvider('channel-1').future,
      );

      expect(unread.hasUnreadPins, isTrue);
    },
  );

  test('serverUnread includes channels without read state rows', () async {
    final db = FluxerDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final channelId = _snowflakeForUtc(DateTime.utc(2026, 5));
    final lastMessageId = _snowflakeForUtc(DateTime.utc(2026, 5, 6));
    await db.channelDao.upsertChannel(
      ChannelsCompanion.insert(
        id: channelId,
        guildId: 'guild-1',
        name: 'general',
        lastMessageId: Value(lastMessageId),
      ),
    );

    final container = _container(db);
    addTearDown(container.dispose);
    final subscription = container.listen(
      serverUnreadProvider('guild-1'),
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    final unread = await container.read(serverUnreadProvider('guild-1').future);

    expect(unread.hasUnread, isTrue);
    expect(unread.mentionCount, 0);
  });
}

ProviderContainer _container(FluxerDatabase db) {
  return ProviderContainer(
    overrides: [fluxerDatabaseProvider.overrideWithValue(db)],
  );
}
