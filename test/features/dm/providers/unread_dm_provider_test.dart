import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/features/dm/providers/unread_dm_provider.dart';

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
  });
}
