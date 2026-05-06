import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/features/channels/data/read_state_repository.dart';
import 'package:fluxer_app/shared/utils/snowflake_time.dart';
import 'package:fluxer_dart/export.dart';

String _snowflakeForUtc(DateTime utc) {
  final int internal = (utc.millisecondsSinceEpoch - kSnowflakeEpochMs) << 22;
  return internal.toString();
}

MessagesCompanion _message({
  required String id,
  required String channelId,
  required String authorId,
  bool isMentioned = false,
}) => MessagesCompanion.insert(
  id: id,
  channelId: channelId,
  authorId: authorId,
  content: 'message $id',
  timestamp: dateTimeFromUserSnowflakeOrNull(id)!,
  isMentioned: Value(isMentioned),
);

void main() {
  test(
    'ackLatest acknowledges the channel last message without cached messages',
    () async {
      final lastMessageId = _snowflakeForUtc(DateTime.utc(2026, 5, 6, 12));
      final dio = Dio(BaseOptions(baseUrl: 'https://api.fluxer.app/v1'))
        ..httpClientAdapter = _AckAdapter(
          expectedPath: '/v1/channels/channel-1/messages/$lastMessageId/ack',
        );
      final db = FluxerDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await db.channelDao.upsertChannel(
        ChannelsCompanion.insert(
          id: 'channel-1',
          guildId: 'guild-1',
          name: 'general',
          lastMessageId: Value(lastMessageId),
        ),
      );
      await db.readStateDao.upsertReadState(
        const ReadStatesCompanion(
          channelId: Value('channel-1'),
          lastMessageId: Value('older-message'),
          mentionCount: Value(2),
        ),
      );

      await ReadStateRepository(FluxerClient(dio), db).ackLatest('channel-1');

      final readState = await db.readStateDao.getReadState('channel-1');
      expect(readState?.lastMessageId, lastMessageId);
      expect(readState?.mentionCount, 0);
    },
  );

  test('ackLatest clears DM unread count from cached latest message', () async {
    final messageId = _snowflakeForUtc(DateTime.utc(2026, 5, 6, 12));
    final dio = Dio(BaseOptions(baseUrl: 'https://api.fluxer.app/v1'))
      ..httpClientAdapter = _AckAdapter(
        expectedPath: '/v1/channels/dm-1/messages/$messageId/ack',
      );
    final db = FluxerDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.dmChannelDao.upsertDmChannels([
      DmChannelsCompanion.insert(
        id: 'dm-1',
        recipientId: 'other',
        unreadCount: const Value(3),
      ),
    ]);
    await db.messageDao.upsertMessage(
      _message(id: messageId, channelId: 'dm-1', authorId: 'other'),
    );

    await ReadStateRepository(FluxerClient(dio), db).ackLatest('dm-1');

    final dm = await db.dmChannelDao.getDmChannelById('dm-1');
    final readState = await db.readStateDao.getReadState('dm-1');
    expect(dm?.unreadCount, 0);
    expect(readState?.lastMessageId, messageId);
  });

  test('ackPins acknowledges latest channel pin timestamp', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.fluxer.app/v1'))
      ..httpClientAdapter = const _AckAdapter(
        expectedPath: '/v1/channels/channel-1/pins/ack',
      );
    final db = FluxerDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    const latestPin = '2026-05-06T12:00:00.000Z';
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
        lastPinTimestamp: Value('2026-05-05T12:00:00.000Z'),
      ),
    );

    await ReadStateRepository(FluxerClient(dio), db).ackPins('channel-1');

    final readState = await db.readStateDao.getReadState('channel-1');
    expect(readState?.lastPinTimestamp, latestPin);
  });

  test('cleanupStaleReadStates deletes remote and local stale rows', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.fluxer.app/v1'))
      ..httpClientAdapter = _RecordingAdapter();
    final db = FluxerDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.channelDao.upsertChannel(
      ChannelsCompanion.insert(
        id: 'channel-1',
        guildId: 'guild-1',
        name: 'general',
      ),
    );
    await db.dmChannelDao.upsertDmChannels([
      DmChannelsCompanion.insert(id: 'dm-1', recipientId: 'other'),
    ]);
    await db.readStateDao.upsertReadState(
      const ReadStatesCompanion(channelId: Value('channel-1')),
    );
    await db.readStateDao.upsertReadState(
      const ReadStatesCompanion(channelId: Value('dm-1')),
    );
    await db.readStateDao.upsertReadState(
      const ReadStatesCompanion(channelId: Value('missing-1')),
    );

    await ReadStateRepository(
      FluxerClient(dio),
      db,
    ).cleanupStaleReadStates(delayBetweenDeletes: Duration.zero);

    final adapter = dio.httpClientAdapter as _RecordingAdapter;
    expect(adapter.requests, [
      ('DELETE', '/v1/channels/missing-1/messages/ack'),
    ]);
    expect(await db.readStateDao.getReadState('missing-1'), null);
    expect(await db.readStateDao.getReadState('channel-1'), isA<ReadState>());
    expect(await db.readStateDao.getReadState('dm-1'), isA<ReadState>());
  });

  test('markMessageUnread manually acks the previous message', () async {
    final firstId = _snowflakeForUtc(DateTime.utc(2026, 5, 6, 12));
    final secondId = _snowflakeForUtc(DateTime.utc(2026, 5, 6, 12, 1));
    final thirdId = _snowflakeForUtc(DateTime.utc(2026, 5, 6, 12, 2));
    final dio = Dio(BaseOptions(baseUrl: 'https://api.fluxer.app/v1'))
      ..httpClientAdapter = _AckAdapter(
        expectedPath: '/v1/channels/channel-1/messages/$firstId/ack',
        expectedBody: <String, Object?>{'mention_count': 1, 'manual': true},
      );
    final db = FluxerDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.messageDao.upsertMessages([
      _message(id: firstId, channelId: 'channel-1', authorId: 'other'),
      _message(id: secondId, channelId: 'channel-1', authorId: 'other'),
      _message(
        id: thirdId,
        channelId: 'channel-1',
        authorId: 'other',
        isMentioned: true,
      ),
    ]);

    await ReadStateRepository(FluxerClient(dio), db).markMessageUnread(
      channelId: 'channel-1',
      messageId: secondId,
      currentUserId: 'me',
    );

    final readState = await db.readStateDao.getReadState('channel-1');
    expect(readState?.lastMessageId, firstId);
    expect(readState?.mentionCount, 1);
  });
}

class _RecordingAdapter implements HttpClientAdapter {
  final List<(String method, String path)> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add((options.method, options.uri.path));
    return ResponseBody.fromString('', 204, statusMessage: 'No Content');
  }

  @override
  void close({bool force = false}) {}
}

class _AckAdapter implements HttpClientAdapter {
  const _AckAdapter({required this.expectedPath, this.expectedBody});

  final String expectedPath;
  final Map<String, Object?>? expectedBody;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    expect(options.method, 'POST');
    expect(options.uri.path, expectedPath);
    if (expectedBody != null) {
      final builder = BytesBuilder();
      if (requestStream != null) {
        await for (final chunk in requestStream) {
          builder.add(chunk);
        }
      }
      final decoded = jsonDecode(utf8.decode(builder.takeBytes()));
      expect(decoded, expectedBody);
    }

    return ResponseBody.fromString('', 204, statusMessage: 'No Content');
  }

  @override
  void close({bool force = false}) {}
}
