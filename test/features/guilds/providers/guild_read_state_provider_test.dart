import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/providers/gateway_ready_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/features/channels/data/read_state_utils.dart';
import 'package:fluxer_app/features/guilds/providers/guild_read_state_provider.dart';
import 'package:fluxer_app/features/guilds/providers/guild_read_state_ready_provider.dart';
import 'package:fluxer_app/shared/utils/snowflake_time.dart';

String _snowflakeForUtc(DateTime utc) {
  final int internal = (utc.millisecondsSinceEpoch - kSnowflakeEpochMs) << 22;
  return internal.toString();
}

DateTime _timestampFromSnowflake(String id) {
  return DateTime.fromMillisecondsSinceEpoch(
    snowflakeTimestampMs(id),
    isUtc: true,
  );
}

MessagesCompanion _cachedMessage({
  required String id,
  required String channelId,
}) => MessagesCompanion.insert(
  id: id,
  channelId: channelId,
  authorId: 'other',
  content: 'message $id',
  timestamp: _timestampFromSnowflake(id),
);

String _recentSnowflake({Duration ago = const Duration(hours: 1)}) {
  return _snowflakeForUtc(DateTime.now().toUtc().subtract(ago));
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
      joinedAt: Value(DateTime.utc(2026)),
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
    if (c.lastMessageId != null) {
      await db.messageDao.upsertMessage(
        _cachedMessage(id: c.lastMessageId!, channelId: c.id),
      );
    }
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

Future<void> _waitFor(bool Function() condition) async {
  for (var i = 0; i < 50; i++) {
    if (condition()) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  fail('condition not met within timeout');
}

Future<void> _waitForGuildState(
  ProviderContainer container,
  String guildId,
) async {
  await _waitFor(() {
    final entry = container.read(guildReadStateProvider)[guildId];
    return entry != null && (entry.hasUnread || entry.mentionCount > 0);
  });
}

void main() {
  test(
    'seeds initial map with hasUnread for channels with new messages',
    () async {
      final db = FluxerDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final lastMessageId = _recentSnowflake();
      await _seedGuild(
        db,
        'guild-1',
        channels: [
          (
            id: 'channel-1',
            name: 'general',
            type: 0,
            lastMessageId: lastMessageId,
          ),
        ],
      );
      await db.readStateDao.upsertReadState(
        ReadStatesCompanion(
          channelId: const Value('channel-1'),
          lastMessageId: Value(snowflakeAtPreviousMillisecond(lastMessageId)),
        ),
      );

      final container = _container(db);
      addTearDown(container.dispose);

      container.read(gatewayReadyProvider.notifier).setReady();
      final sub = container.listen(
        guildReadStateProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);
      await _waitForGuildState(container, 'guild-1');

      final state = container.read(guildReadStateProvider);
      expect(state['guild-1'], isNotNull);
      expect(state['guild-1']!.hasUnread, isTrue);
      expect(state['guild-1']!.hasPlainUnread, isTrue);
      expect(state['guild-1']!.mentionCount, 0);
    },
  );

  test('incremental update bumps sentinel only for affected guild', () async {
    final db = FluxerDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final lastA = _recentSnowflake();
    final lastB = _recentSnowflake(ago: const Duration(minutes: 30));
    await _seedGuild(
      db,
      'guild-A',
      channels: [(id: 'c-A1', name: 'a1', type: 0, lastMessageId: lastA)],
    );
    await _seedGuild(
      db,
      'guild-B',
      channels: [(id: 'c-B1', name: 'b1', type: 0, lastMessageId: lastB)],
    );
    await db.readStateDao.upsertReadState(
      ReadStatesCompanion(
        channelId: const Value('c-A1'),
        lastMessageId: Value(snowflakeAtPreviousMillisecond(lastA)),
      ),
    );
    await db.readStateDao.upsertReadState(
      ReadStatesCompanion(
        channelId: const Value('c-B1'),
        lastMessageId: Value(snowflakeAtPreviousMillisecond(lastB)),
      ),
    );

    final container = _container(db);
    addTearDown(container.dispose);
    container.read(gatewayReadyProvider.notifier).setReady();
    final sub = container.listen(
      guildReadStateProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(sub.close);
    await _waitForGuildState(container, 'guild-A');
    await _waitForGuildState(container, 'guild-B');

    final beforeA = container.read(guildReadStateProvider)['guild-A']!;
    final beforeB = container.read(guildReadStateProvider)['guild-B']!;

    await db.readStateDao.incrementMentionCount('c-A1');
    await _waitFor(
      () =>
          (container.read(guildReadStateProvider)['guild-A']?.mentionCount ??
              0) >
          beforeA.mentionCount,
    );

    final afterA = container.read(guildReadStateProvider)['guild-A']!;
    final afterB = container.read(guildReadStateProvider)['guild-B']!;

    expect(afterA.mentionCount, beforeA.mentionCount + 1);
    expect(afterA.sentinel, greaterThan(beforeA.sentinel));
    expect(identical(afterB, beforeB), isTrue);
  });

  test('voice channels contribute plain unread like text channels', () async {
    final db = FluxerDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final lastVoice = _recentSnowflake();
    await _seedGuild(
      db,
      'guild-1',
      channels: [
        (id: 'voice-1', name: 'voice', type: 2, lastMessageId: lastVoice),
      ],
    );
    await db.readStateDao.upsertReadState(
      ReadStatesCompanion(
        channelId: const Value('voice-1'),
        lastMessageId: Value(snowflakeAtPreviousMillisecond(lastVoice)),
      ),
    );

    final container = _container(db);
    addTearDown(container.dispose);
    container.read(gatewayReadyProvider.notifier).setReady();
    final sub = container.listen(
      guildReadStateProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(sub.close);
    await _waitForGuildState(container, 'guild-1');

    final entry = container.read(guildReadStateProvider)['guild-1'];
    expect(entry?.hasUnread, isTrue);
    expect(entry?.hasPlainUnread, isTrue);
    expect(entry?.mentionCount, 0);
  });

  test('category channels do not contribute to guild unread', () async {
    final db = FluxerDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final lastMessageId = _recentSnowflake();
    await _seedGuild(
      db,
      'guild-1',
      channels: [
        (
          id: 'category-1',
          name: 'category',
          type: 4,
          lastMessageId: lastMessageId,
        ),
      ],
    );
    await db.readStateDao.upsertReadState(
      ReadStatesCompanion(
        channelId: const Value('category-1'),
        lastMessageId: Value(snowflakeAtPreviousMillisecond(lastMessageId)),
      ),
    );

    final container = _container(db);
    addTearDown(container.dispose);
    container.read(gatewayReadyProvider.notifier).setReady();
    final sub = container.listen(
      guildReadStateProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(sub.close);
    await _waitFor(
      () => container.read(guildReadStateProvider)['guild-1'] != null,
    );

    final entry = container.read(guildReadStateProvider)['guild-1'];
    expect(entry?.hasUnread ?? false, isFalse);
    expect(entry?.hasPlainUnread ?? false, isFalse);
    expect(entry?.mentionCount ?? 0, 0);
  });

  test('recomputes guild unread when a newer cached message arrives', () async {
    final db = FluxerDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final readMessageId = _recentSnowflake();
    final newerMessageId = _recentSnowflake(ago: const Duration(minutes: 30));
    await db.guildDao.upsertServer(
      ServersCompanion.insert(
        id: 'guild-1',
        name: 'Guild guild-1',
        ownerId: const Value('owner'),
      ),
    );
    await db.memberDao.upsertMember(
      MembersCompanion.insert(
        userId: 'me',
        guildId: 'guild-1',
        joinedAt: Value(DateTime.utc(2026)),
      ),
    );
    await db.channelDao.upsertChannel(
      ChannelsCompanion.insert(
        id: 'channel-1',
        guildId: 'guild-1',
        name: 'general',
        type: const Value(0),
      ),
    );
    await db.channelDao.setLastMessageId('channel-1', readMessageId);
    await db.readStateDao.upsertReadState(
      ReadStatesCompanion(
        channelId: const Value('channel-1'),
        lastMessageId: Value(readMessageId),
      ),
    );

    final container = _container(db);
    addTearDown(container.dispose);
    container.read(gatewayReadyProvider.notifier).setReady();
    final sub = container.listen(
      guildReadStateProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(sub.close);
    await _waitFor(
      () => container.read(guildReadStateProvider)['guild-1'] != null,
    );

    expect(
      container.read(guildReadStateProvider)['guild-1']?.hasUnread ?? true,
      isFalse,
    );

    await db.messageDao.upsertMessage(
      _cachedMessage(id: newerMessageId, channelId: 'channel-1'),
    );
    await _waitForGuildState(container, 'guild-1');

    final after = container.read(guildReadStateProvider)['guild-1']!;
    expect(after.hasUnread, isTrue);
    expect(after.hasPlainUnread, isTrue);
  });

  test(
    'shows unread for orphaned channel pointer via read state fallback',
    () async {
      final db = FluxerDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final lastMessageId = _recentSnowflake();
      final ackId = snowflakeAtPreviousMillisecond(lastMessageId);
      await db.guildDao.upsertServer(
        ServersCompanion.insert(
          id: 'guild-1',
          name: 'Guild guild-1',
          ownerId: const Value('owner'),
        ),
      );
      await db.memberDao.upsertMember(
        MembersCompanion.insert(
          userId: 'me',
          guildId: 'guild-1',
          joinedAt: Value(DateTime.utc(2026)),
        ),
      );
      await db.channelDao.upsertChannel(
        ChannelsCompanion.insert(
          id: 'channel-1',
          guildId: 'guild-1',
          name: 'general',
          type: const Value(0),
        ),
      );
      await db.channelDao.setLastMessageId('channel-1', lastMessageId);
      await db.readStateDao.upsertReadState(
        ReadStatesCompanion(
          channelId: const Value('channel-1'),
          lastMessageId: Value(ackId),
        ),
      );

      final container = _container(db);
      addTearDown(container.dispose);
      container.read(gatewayReadyProvider.notifier).setReady();
      final sub = container.listen(
        guildReadStateProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);
      await _waitForGuildState(container, 'guild-1');

      final entry = container.read(guildReadStateProvider)['guild-1'];
      expect(entry?.hasUnread, isTrue);
      expect(entry?.hasPlainUnread, isTrue);
    },
  );

  test(
    'guildReadStateReadyProvider is false until initial seed completes',
    () async {
      final db = FluxerDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final lastMessageId = _recentSnowflake();
      await _seedGuild(
        db,
        'guild-1',
        channels: [
          (
            id: 'channel-1',
            name: 'general',
            type: 0,
            lastMessageId: lastMessageId,
          ),
        ],
      );
      await db.readStateDao.upsertReadState(
        ReadStatesCompanion(
          channelId: const Value('channel-1'),
          lastMessageId: Value(snowflakeAtPreviousMillisecond(lastMessageId)),
        ),
      );

      final container = _container(db);
      addTearDown(container.dispose);

      expect(container.read(guildReadStateReadyProvider), isFalse);

      container.read(gatewayReadyProvider.notifier).setReady();
      final sub = container.listen(
        guildReadStateProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);
      await _waitForGuildState(container, 'guild-1');

      expect(container.read(guildReadStateReadyProvider), isTrue);
    },
  );

  test(
    'initial seed publishes unread once without stream-driven pre-seed recompute',
    () async {
      final db = FluxerDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final lastMessageId = _recentSnowflake();
      await _seedGuild(
        db,
        'guild-1',
        channels: [
          (
            id: 'channel-1',
            name: 'general',
            type: 0,
            lastMessageId: lastMessageId,
          ),
        ],
      );
      await db.readStateDao.upsertReadState(
        ReadStatesCompanion(
          channelId: const Value('channel-1'),
          lastMessageId: Value(snowflakeAtPreviousMillisecond(lastMessageId)),
        ),
      );

      final container = _container(db);
      addTearDown(container.dispose);

      final unreadSnapshots = <bool?>[];
      container.listen(guildReadStateProvider, (previous, next) {
        unreadSnapshots.add(next['guild-1']?.hasUnread);
      }, fireImmediately: true);

      container.read(gatewayReadyProvider.notifier).setReady();
      await _waitFor(() => container.read(guildReadStateReadyProvider));

      expect(
        unreadSnapshots.where((hasUnread) => hasUnread ?? false).length,
        1,
      );
      expect(
        container.read(guildReadStateProvider)['guild-1']?.hasUnread,
        isTrue,
      );
    },
  );

  test('settings stream update after seed keeps stable unread state', () async {
    final db = FluxerDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final lastMessageId = _recentSnowflake();
    await _seedGuild(
      db,
      'guild-1',
      channels: [
        (
          id: 'channel-1',
          name: 'general',
          type: 0,
          lastMessageId: lastMessageId,
        ),
      ],
    );
    await db.readStateDao.upsertReadState(
      ReadStatesCompanion(
        channelId: const Value('channel-1'),
        lastMessageId: Value(snowflakeAtPreviousMillisecond(lastMessageId)),
      ),
    );

    final container = _container(db);
    addTearDown(container.dispose);
    container.read(gatewayReadyProvider.notifier).setReady();
    final sub = container.listen(
      guildReadStateProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(sub.close);
    await _waitForGuildState(container, 'guild-1');

    expect(
      container.read(guildReadStateProvider)['guild-1']?.hasUnread,
      isTrue,
    );

    await db.userGuildSettingsDao.upsert(
      UserGuildSettingsTableCompanion.insert(
        guildId: 'guild-1',
        data: '{"message_notifications":0}',
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(
      container.read(guildReadStateProvider)['guild-1']?.hasUnread,
      isTrue,
    );
  });

  test('buffers read state updates emitted during initial seed', () async {
    final db = FluxerDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final ackId = _recentSnowflake(ago: const Duration(hours: 2));
    final latestId = _recentSnowflake(ago: const Duration(hours: 1));
    await _seedGuild(
      db,
      'guild-1',
      channels: [
        (id: 'channel-1', name: 'general', type: 0, lastMessageId: latestId),
      ],
    );
    await db.readStateDao.upsertReadState(
      ReadStatesCompanion(
        channelId: const Value('channel-1'),
        lastMessageId: Value(latestId),
      ),
    );

    final container = _container(db);
    addTearDown(container.dispose);
    container.listen(guildReadStateProvider, (_, _) {}, fireImmediately: true);

    container.read(gatewayReadyProvider.notifier).setReady();
    await db.readStateDao.upsertReadState(
      ReadStatesCompanion(
        channelId: const Value('channel-1'),
        lastMessageId: Value(ackId),
      ),
    );
    await _waitForGuildState(container, 'guild-1');

    final entry = container.read(guildReadStateProvider)['guild-1'];
    expect(entry?.hasUnread, isTrue);
    expect(entry?.hasPlainUnread, isTrue);
  });
}
