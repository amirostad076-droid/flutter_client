import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/providers/gateway_ready_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/features/guilds/providers/guild_read_state_provider.dart';
import 'package:fluxer_app/shared/utils/snowflake_time.dart';

String _snowflakeForUtc(DateTime utc) {
  final int internal = (utc.millisecondsSinceEpoch - kSnowflakeEpochMs) << 22;
  return internal.toString();
}

Future<void> _seedGuild(
  FluxerDatabase db,
  String guildId, {
  List<({String id, String name, int type, String? lastMessageId})> channels =
      const [],
}) async {
  await db.guildDao.upsertServer(
    ServersCompanion.insert(
      id: guildId,
      name: 'Guild $guildId',
      ownerId: const Value('owner'),
    ),
  );
  await db.memberDao.upsertMember(
    MembersCompanion.insert(
      userId: 'me',
      guildId: guildId,
      joinedAt: Value(DateTime.utc(2026, 1, 1)),
    ),
  );
  for (final c in channels) {
    await db.channelDao.upsertChannel(
      ChannelsCompanion.insert(
        id: c.id,
        guildId: guildId,
        name: c.name,
        type: Value(c.type),
        lastMessageId: Value(c.lastMessageId),
      ),
    );
  }
}

ProviderContainer _container(FluxerDatabase db) {
  return ProviderContainer(
    overrides: [
      fluxerDatabaseProvider.overrideWithValue(db),
      currentUserIdProvider.overrideWithValue('me'),
    ],
  );
}

void main() {
  test('seeds initial map with hasUnread for channels with new messages',
      () async {
    final db = FluxerDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final lastMessageId = _snowflakeForUtc(DateTime.utc(2026, 5, 14));
    await _seedGuild(
      db,
      'guild-1',
      channels: [
        (id: 'channel-1', name: 'general', type: 0, lastMessageId: lastMessageId),
      ],
    );
    await db.readStateDao.upsertReadState(
      const ReadStatesCompanion(
        channelId: Value('channel-1'),
        lastMessageId: Value('older-message'),
      ),
    );

    final container = _container(db);
    addTearDown(container.dispose);

    container.read(gatewayReadyProvider.notifier).setReady();
    final sub = container.listen(guildReadStateProvider, (_, _) {},
        fireImmediately: true);
    addTearDown(sub.close);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final state = container.read(guildReadStateProvider);
    expect(state['guild-1'], isNotNull);
    expect(state['guild-1']!.hasUnread, isTrue);
    expect(state['guild-1']!.mentionCount, 0);
  });

  test(
    'incremental update bumps sentinel only for affected guild',
    () async {
      final db = FluxerDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final lastA = _snowflakeForUtc(DateTime.utc(2026, 5, 14));
      final lastB = _snowflakeForUtc(DateTime.utc(2026, 5, 14, 1));
      await _seedGuild(
        db,
        'guild-A',
        channels: [
          (id: 'c-A1', name: 'a1', type: 0, lastMessageId: lastA),
        ],
      );
      await _seedGuild(
        db,
        'guild-B',
        channels: [
          (id: 'c-B1', name: 'b1', type: 0, lastMessageId: lastB),
        ],
      );
      await db.readStateDao.upsertReadState(
        const ReadStatesCompanion(
          channelId: Value('c-A1'),
          lastMessageId: Value('old-A'),
        ),
      );
      await db.readStateDao.upsertReadState(
        const ReadStatesCompanion(
          channelId: Value('c-B1'),
          lastMessageId: Value('old-B'),
        ),
      );

      final container = _container(db);
      addTearDown(container.dispose);
      container.read(gatewayReadyProvider.notifier).setReady();
      final sub = container.listen(guildReadStateProvider, (_, _) {},
          fireImmediately: true);
      addTearDown(sub.close);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final beforeA = container.read(guildReadStateProvider)['guild-A']!;
      final beforeB = container.read(guildReadStateProvider)['guild-B']!;

      await db.readStateDao.incrementMentionCount('c-A1');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final afterA = container.read(guildReadStateProvider)['guild-A']!;
      final afterB = container.read(guildReadStateProvider)['guild-B']!;

      expect(afterA.mentionCount, beforeA.mentionCount + 1);
      expect(afterA.sentinel, greaterThan(beforeA.sentinel));
      expect(identical(afterB, beforeB), isTrue);
    },
  );

  test('voice channels do not contribute plain unread but do for mentions',
      () async {
    final db = FluxerDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final lastVoice = _snowflakeForUtc(DateTime.utc(2026, 5, 14));
    await _seedGuild(
      db,
      'guild-1',
      channels: [
        (id: 'voice-1', name: 'voice', type: 2, lastMessageId: lastVoice),
      ],
    );
    await db.readStateDao.upsertReadState(
      const ReadStatesCompanion(
        channelId: Value('voice-1'),
        lastMessageId: Value('old-voice'),
      ),
    );

    final container = _container(db);
    addTearDown(container.dispose);
    container.read(gatewayReadyProvider.notifier).setReady();
    final sub = container.listen(guildReadStateProvider, (_, _) {},
        fireImmediately: true);
    addTearDown(sub.close);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final entry = container.read(guildReadStateProvider)['guild-1'];
    expect(entry?.hasUnread ?? false, isFalse);
    expect(entry?.mentionCount ?? 0, 0);
  });
}
