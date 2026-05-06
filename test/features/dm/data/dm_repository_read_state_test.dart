import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/features/dm/data/dm_repository.dart';
import 'package:fluxer_app/shared/utils/snowflake_time.dart';
import 'package:fluxer_dart/export.dart';

String _snowflakeForUtc(DateTime utc) {
  final int internal = (utc.millisecondsSinceEpoch - kSnowflakeEpochMs) << 22;
  return internal.toString();
}

void main() {
  test(
    'watchDmChannels derives unread count from read state mention count',
    () async {
      final db = FluxerDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await db.userDao.upsertUser(
        UsersCompanion.insert(id: 'other', username: 'Other'),
      );
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

      final repo = DmRepository(
        FluxerClient(Dio(BaseOptions(baseUrl: 'https://api.fluxer.app/v1'))),
        db,
      );

      final conversations = await repo.watchDmChannels().first;

      expect(conversations.single.unreadCount, 2);
    },
  );

  test(
    'watchDmChannels derives unread when ack is behind latest DM message',
    () async {
      final db = FluxerDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final ackId = _snowflakeForUtc(DateTime.utc(2026, 5, 6, 12));
      final latestId = _snowflakeForUtc(DateTime.utc(2026, 5, 6, 12, 1));
      await db.userDao.upsertUser(
        UsersCompanion.insert(id: 'other', username: 'Other'),
      );
      await db.dmChannelDao.upsertDmChannels([
        DmChannelsCompanion.insert(
          id: 'dm-1',
          recipientId: 'other',
          unreadCount: const Value(0),
        ),
      ]);
      await db.messageDao.upsertMessage(
        MessagesCompanion.insert(
          id: latestId,
          channelId: 'dm-1',
          authorId: 'other',
          content: 'hello',
          timestamp: dateTimeFromUserSnowflakeOrNull(latestId)!,
        ),
      );
      await db.readStateDao.upsertReadState(
        ReadStatesCompanion(
          channelId: const Value('dm-1'),
          lastMessageId: Value(ackId),
          mentionCount: const Value(0),
        ),
      );

      final repo = DmRepository(
        FluxerClient(Dio(BaseOptions(baseUrl: 'https://api.fluxer.app/v1'))),
        db,
      );

      final conversations = await repo.watchDmChannels().first;

      expect(conversations.single.unreadCount, 1);
    },
  );

  test('watchDmChannels derives unread from DM latest message id without read '
      'state', () async {
    final db = FluxerDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final dmId = _snowflakeForUtc(DateTime.utc(2026, 5, 6, 12));
    final latestId = _snowflakeForUtc(DateTime.utc(2026, 5, 6, 12, 1));
    await db.userDao.upsertUser(
      UsersCompanion.insert(id: 'other', username: 'Other'),
    );
    await db.dmChannelDao.upsertDmChannels([
      DmChannelsCompanion.insert(
        id: dmId,
        recipientId: 'other',
        lastMessageId: Value(latestId),
        unreadCount: const Value(0),
      ),
    ]);

    final repo = DmRepository(
      FluxerClient(Dio(BaseOptions(baseUrl: 'https://api.fluxer.app/v1'))),
      db,
    );

    final conversations = await repo.watchDmChannels().first;

    expect(conversations.single.unreadCount, 1);
  });

  test(
    'watchDmChannels derives unread from DM latest message id with null ack',
    () async {
      final db = FluxerDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final dmId = _snowflakeForUtc(DateTime.utc(2026, 5, 6, 12));
      final latestId = _snowflakeForUtc(DateTime.utc(2026, 5, 6, 12, 1));
      await db.userDao.upsertUser(
        UsersCompanion.insert(id: 'other', username: 'Other'),
      );
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
          lastMessageId: const Value(null),
          mentionCount: const Value(0),
        ),
      );

      final repo = DmRepository(
        FluxerClient(Dio(BaseOptions(baseUrl: 'https://api.fluxer.app/v1'))),
        db,
      );

      final conversations = await repo.watchDmChannels().first;

      expect(conversations.single.unreadCount, 1);
    },
  );

  test(
    'watchDmChannels derives unread from DM latest message id without cache',
    () async {
      final db = FluxerDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final ackId = _snowflakeForUtc(DateTime.utc(2026, 5, 6, 12));
      final latestId = _snowflakeForUtc(DateTime.utc(2026, 5, 6, 12, 1));
      await db.userDao.upsertUser(
        UsersCompanion.insert(id: 'other', username: 'Other'),
      );
      await db.dmChannelDao.upsertDmChannels([
        DmChannelsCompanion.insert(
          id: 'dm-1',
          recipientId: 'other',
          lastMessageId: Value(latestId),
          unreadCount: const Value(0),
        ),
      ]);
      await db.readStateDao.upsertReadState(
        ReadStatesCompanion(
          channelId: const Value('dm-1'),
          lastMessageId: Value(ackId),
          mentionCount: const Value(0),
        ),
      );

      final repo = DmRepository(
        FluxerClient(Dio(BaseOptions(baseUrl: 'https://api.fluxer.app/v1'))),
        db,
      );

      final conversations = await repo.watchDmChannels().first;

      expect(conversations.single.unreadCount, 1);
    },
  );

  test('watchDmChannels reacts to read state changes', () async {
    final db = FluxerDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.userDao.upsertUser(
      UsersCompanion.insert(id: 'other', username: 'Other'),
    );
    await db.dmChannelDao.upsertDmChannels([
      DmChannelsCompanion.insert(
        id: 'dm-1',
        recipientId: 'other',
        unreadCount: const Value(0),
      ),
    ]);

    final repo = DmRepository(
      FluxerClient(Dio(BaseOptions(baseUrl: 'https://api.fluxer.app/v1'))),
      db,
    );
    final iterator = StreamIterator(repo.watchDmChannels());
    addTearDown(iterator.cancel);

    expect(await iterator.moveNext(), isTrue);
    expect(iterator.current, hasLength(1));

    await db.readStateDao.upsertReadState(
      const ReadStatesCompanion(
        channelId: Value('dm-1'),
        mentionCount: Value(3),
      ),
    );

    while (await iterator.moveNext()) {
      if (iterator.current.single.unreadCount == 3) {
        break;
      }
    }
    expect(iterator.current.single.unreadCount, 3);
  });
}
