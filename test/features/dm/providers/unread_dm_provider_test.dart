import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/features/dm/providers/unread_dm_provider.dart';

String _snowflakeForUtc(DateTime utc) {
  const epoch = 1420070400000;
  final internal = (utc.millisecondsSinceEpoch - epoch) << 22;
  return internal.toString();
}

void main() {
  test('unread DM provider derives unread channels from read states', () async {
    final db = FluxerDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.dmChannelDao.upsertDmChannels([
      DmChannelsCompanion.insert(
        id: 'dm-1',
        recipientId: 'other',
        unreadCount: const Value(0),
      ),
    ]);
    await db.readStateDao.upsertReadState(
      const ReadStatesCompanion(
        channelId: Value('dm-1'),
        mentionCount: Value(2),
      ),
    );
    final container = ProviderContainer(
      overrides: [fluxerDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    final subscription = container.listen(
      unreadDmChannelsProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await pumpEventQueue();
    final state = container.read(unreadDmChannelsProvider);

    expect(state.channels.map((channel) => channel.id), ['dm-1']);
    expect(state.channels.single.unreadCount, 2);
    expect(state.hasUnread('dm-1'), isTrue);
  });

  test(
    'unread DM provider separates unread presence from mention badges',
    () async {
      final db = FluxerDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final dmId = _snowflakeForUtc(DateTime.utc(2026, 5, 6, 12));
      final ackId = _snowflakeForUtc(DateTime.utc(2026, 5, 6, 12, 1));
      final latestId = _snowflakeForUtc(DateTime.utc(2026, 5, 6, 12, 2));
      await db.dmChannelDao.upsertDmChannels([
        DmChannelsCompanion.insert(
          id: dmId,
          recipientId: 'other',
          lastMessageId: Value(latestId),
          unreadCount: const Value(0),
        ),
      ]);
      await db.readStateDao.upsertReadState(
        ReadStatesCompanion(
          channelId: Value(dmId),
          lastMessageId: Value(ackId),
          mentionCount: const Value(0),
        ),
      );
      final container = ProviderContainer(
        overrides: [fluxerDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      final subscription = container.listen(
        unreadDmChannelsProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      await pumpEventQueue();
      final state = container.read(unreadDmChannelsProvider);

      expect(state.channels.map((channel) => channel.id), [dmId]);
      expect(state.channels.single.unreadCount, 0);
      expect(state.hasUnread(dmId), isTrue);
    },
  );

  test('unread DM provider preserves channel order when only data updates', () async {
    final db = FluxerDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.dmChannelDao.upsertDmChannels([
      DmChannelsCompanion.insert(
        id: 'dm-older',
        recipientId: 'other-a',
        lastMessageTime: Value(DateTime.utc(2026, 1, 1)),
        unreadCount: const Value(0),
      ),
      DmChannelsCompanion.insert(
        id: 'dm-newer',
        recipientId: 'other-b',
        lastMessageTime: Value(DateTime.utc(2026, 1, 2)),
        unreadCount: const Value(0),
      ),
    ]);
    await db.readStateDao.upsertReadState(
      const ReadStatesCompanion(
        channelId: Value('dm-older'),
        mentionCount: Value(1),
      ),
    );
    await db.readStateDao.upsertReadState(
      const ReadStatesCompanion(
        channelId: Value('dm-newer'),
        mentionCount: Value(1),
      ),
    );
    final container = ProviderContainer(
      overrides: [fluxerDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    final subscription = container.listen(
      unreadDmChannelsProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await pumpEventQueue();
    final initialOrder = container
        .read(unreadDmChannelsProvider)
        .channels
        .map((channel) => channel.id)
        .toList();
    expect(initialOrder, containsAll(['dm-older', 'dm-newer']));

    await db.readStateDao.upsertReadState(
      const ReadStatesCompanion(
        channelId: Value('dm-older'),
        mentionCount: Value(2),
      ),
    );
    await pumpEventQueue();

    final updatedOrder = container
        .read(unreadDmChannelsProvider)
        .channels
        .map((channel) => channel.id)
        .toList();
    expect(updatedOrder, initialOrder);
    expect(
      container.read(unreadDmChannelsProvider).channels.singleWhere(
        (channel) => channel.id == 'dm-older',
      ).unreadCount,
      2,
    );
  });
}
