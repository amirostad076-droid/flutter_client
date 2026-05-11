import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/providers/app_ui_lifecycle_provider.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/features/chat/providers/chat_view_model.dart';
import 'package:fluxer_app/shared/utils/snowflake_time.dart';
import 'package:fluxer_dart/export.dart';

String _snowflakeForUtc(DateTime utc) {
  final int internal = (utc.millisecondsSinceEpoch - kSnowflakeEpochMs) << 22;
  return internal.toString();
}

Map<String, Object?> _messageJson({
  required String id,
  required String channelId,
  required String authorId,
}) => <String, Object?>{
  'id': id,
  'channel_id': channelId,
  'author': <String, Object?>{
    'id': authorId,
    'username': 'user-$authorId',
    'discriminator': '0001',
    'global_name': null,
    'avatar': null,
    'avatar_color': null,
    'flags': 0,
  },
  'type': 0,
  'flags': 0,
  'content': 'message $id',
  'timestamp': dateTimeFromUserSnowflakeOrNull(id)!.toIso8601String(),
  'pinned': false,
  'mention_everyone': false,
};

void main() {
  test(
    'switchChannel honors loadMessages false when target is provided',
    () async {
      final db = FluxerDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final adapter = _ChatAdapter(initialMessages: const []);
      final container = _container(db, adapter);
      addTearDown(container.dispose);

      final notifier = container.read(chatViewModelProvider.notifier);
      await notifier.switchChannel(
        'channel-1',
        targetMessageId: 'message-1',
        loadMessages: false,
      );

      final state = container.read(chatViewModelProvider);
      expect(state.channelId, 'channel-1');
      expect(state.messages, isEmpty);
      expect(state.isLoading, isFalse);
      expect(adapter.messageRequestUris, isEmpty);
    },
  );

  test('auto ack preserves sticky unread divider after ack advances', () async {
    final db = FluxerDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final ackId = _snowflakeForUtc(DateTime.utc(2026, 5, 6, 11));
    final unreadId = _snowflakeForUtc(DateTime.utc(2026, 5, 6, 12));
    final latestId = _snowflakeForUtc(DateTime.utc(2026, 5, 6, 13));
    await db.channelDao.upsertChannel(
      ChannelsCompanion.insert(
        id: 'channel-1',
        guildId: 'guild-1',
        name: 'general',
        lastMessageId: Value(latestId),
      ),
    );
    await db.readStateDao.upsertReadState(
      ReadStatesCompanion(
        channelId: const Value('channel-1'),
        lastMessageId: Value(ackId),
        mentionCount: const Value(0),
      ),
    );
    final adapter = _ChatAdapter(
      initialMessages: [
        _messageJson(id: latestId, channelId: 'channel-1', authorId: 'other'),
        _messageJson(id: unreadId, channelId: 'channel-1', authorId: 'other'),
        _messageJson(id: ackId, channelId: 'channel-1', authorId: 'other'),
      ],
    );
    final container = _container(db, adapter);
    addTearDown(container.dispose);

    final notifier = container.read(chatViewModelProvider.notifier);
    await notifier.switchChannel('channel-1');
    notifier.setReadViewportActive(isActive: true);
    await _flushAsync();

    final readState = await db.readStateDao.getReadState('channel-1');
    expect(readState?.lastMessageId, latestId);
    expect(
      container.read(chatViewModelProvider).stickyUnreadMessageId,
      unreadId,
    );
  });

  test(
    'auto ack does not preserve sticky unread divider for own messages',
    () async {
      final db = FluxerDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final ackId = _snowflakeForUtc(DateTime.utc(2026, 5, 6, 11));
      final ownId = _snowflakeForUtc(DateTime.utc(2026, 5, 6, 12));
      await db.channelDao.upsertChannel(
        ChannelsCompanion.insert(
          id: 'channel-1',
          guildId: 'guild-1',
          name: 'general',
          lastMessageId: Value(ownId),
        ),
      );
      await db.readStateDao.upsertReadState(
        ReadStatesCompanion(
          channelId: const Value('channel-1'),
          lastMessageId: Value(ackId),
          mentionCount: const Value(0),
        ),
      );
      final adapter = _ChatAdapter(
        initialMessages: [
          _messageJson(id: ownId, channelId: 'channel-1', authorId: 'me'),
          _messageJson(id: ackId, channelId: 'channel-1', authorId: 'other'),
        ],
      );
      final container = _container(db, adapter);
      addTearDown(container.dispose);

      final notifier = container.read(chatViewModelProvider.notifier);
      await notifier.switchChannel('channel-1');
      notifier.setReadViewportActive(isActive: true);
      await _flushAsync();

      final readState = await db.readStateDao.getReadState('channel-1');
      expect(readState?.lastMessageId, ownId);
      expect(container.read(chatViewModelProvider).stickyUnreadMessageId, null);
    },
  );

  test(
    'auto ack fetches missing unread boundary before preserving divider',
    () async {
      final db = FluxerDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final ackId = _snowflakeForUtc(DateTime.utc(2026, 5, 6, 10));
      final boundaryId = _snowflakeForUtc(DateTime.utc(2026, 5, 6, 11));
      final latestId = _snowflakeForUtc(DateTime.utc(2026, 5, 6, 13));
      await db.channelDao.upsertChannel(
        ChannelsCompanion.insert(
          id: 'channel-1',
          guildId: 'guild-1',
          name: 'general',
          lastMessageId: Value(latestId),
        ),
      );
      await db.readStateDao.upsertReadState(
        ReadStatesCompanion(
          channelId: const Value('channel-1'),
          lastMessageId: Value(ackId),
          mentionCount: const Value(0),
        ),
      );
      final adapter = _ChatAdapter(
        initialMessages: [
          _messageJson(id: latestId, channelId: 'channel-1', authorId: 'other'),
        ],
        messagesAfterAck: [
          _messageJson(
            id: boundaryId,
            channelId: 'channel-1',
            authorId: 'other',
          ),
        ],
      );
      final container = _container(db, adapter);
      addTearDown(container.dispose);

      final notifier = container.read(chatViewModelProvider.notifier);
      await notifier.switchChannel('channel-1');
      notifier.setReadViewportActive(isActive: true);
      await _flushAsync();

      expect(adapter.afterQueries, [ackId]);
      final messages = container.read(chatViewModelProvider).messages;
      expect(messages.map((message) => message.id), [boundaryId, latestId]);
      expect(
        container.read(chatViewModelProvider).stickyUnreadMessageId,
        boundaryId,
      );
    },
  );

  test('auto ack waits while app UI is not foreground', () async {
    final db = FluxerDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final ackId = _snowflakeForUtc(DateTime.utc(2026, 5, 6, 11));
    final latestId = _snowflakeForUtc(DateTime.utc(2026, 5, 6, 12));
    await db.channelDao.upsertChannel(
      ChannelsCompanion.insert(
        id: 'channel-1',
        guildId: 'guild-1',
        name: 'general',
        lastMessageId: Value(latestId),
      ),
    );
    await db.readStateDao.upsertReadState(
      ReadStatesCompanion(
        channelId: const Value('channel-1'),
        lastMessageId: Value(ackId),
        mentionCount: const Value(0),
      ),
    );
    final adapter = _ChatAdapter(
      initialMessages: [
        _messageJson(id: latestId, channelId: 'channel-1', authorId: 'other'),
        _messageJson(id: ackId, channelId: 'channel-1', authorId: 'other'),
      ],
    );
    final container = _container(db, adapter, foreground: false);
    addTearDown(container.dispose);

    final notifier = container.read(chatViewModelProvider.notifier);
    await notifier.switchChannel('channel-1');
    notifier.setReadViewportActive(isActive: true);
    await _flushAsync();

    final readState = await db.readStateDao.getReadState('channel-1');
    expect(readState?.lastMessageId, ackId);
    expect(adapter.ackedMessageIds, isEmpty);
  });

  test('auto ack retries HTTP failure after applying local ack', () async {
    final db = FluxerDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final ackId = _snowflakeForUtc(DateTime.utc(2026, 5, 6, 11));
    final latestId = _snowflakeForUtc(DateTime.utc(2026, 5, 6, 12));
    await db.channelDao.upsertChannel(
      ChannelsCompanion.insert(
        id: 'channel-1',
        guildId: 'guild-1',
        name: 'general',
        lastMessageId: Value(latestId),
      ),
    );
    await db.readStateDao.upsertReadState(
      ReadStatesCompanion(
        channelId: const Value('channel-1'),
        lastMessageId: Value(ackId),
        mentionCount: const Value(1),
      ),
    );
    final adapter = _ChatAdapter(
      initialMessages: [
        _messageJson(id: latestId, channelId: 'channel-1', authorId: 'other'),
        _messageJson(id: ackId, channelId: 'channel-1', authorId: 'other'),
      ],
    )..failAckAttempts = 1;
    final container = _container(db, adapter);
    addTearDown(container.dispose);

    final notifier = container.read(chatViewModelProvider.notifier);
    await notifier.switchChannel('channel-1');
    notifier.setReadViewportActive(isActive: true);
    await _flushAsync();
    await Future<void>.delayed(const Duration(seconds: 6));
    await _flushAsync();

    expect(adapter.ackAttempts, greaterThanOrEqualTo(2));
    expect(adapter.ackedMessageIds, contains(latestId));
  });

  test(
    'manual read state suppresses auto ack until explicitly marked read',
    () async {
      final db = FluxerDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final ackId = _snowflakeForUtc(DateTime.utc(2026, 5, 6, 11));
      final latestId = _snowflakeForUtc(DateTime.utc(2026, 5, 6, 12));
      await db.channelDao.upsertChannel(
        ChannelsCompanion.insert(
          id: 'channel-1',
          guildId: 'guild-1',
          name: 'general',
          lastMessageId: Value(latestId),
        ),
      );
      await db.readStateDao.upsertReadState(
        ReadStatesCompanion(
          channelId: const Value('channel-1'),
          lastMessageId: Value(ackId),
          mentionCount: const Value(0),
          manual: const Value(true),
        ),
      );
      final adapter = _ChatAdapter(
        initialMessages: [
          _messageJson(id: latestId, channelId: 'channel-1', authorId: 'other'),
          _messageJson(id: ackId, channelId: 'channel-1', authorId: 'other'),
        ],
      );
      final container = _container(db, adapter);
      addTearDown(container.dispose);

      final notifier = container.read(chatViewModelProvider.notifier);
      await notifier.switchChannel('channel-1');
      notifier.setReadViewportActive(isActive: true);
      await _flushAsync();

      var readState = await db.readStateDao.getReadState('channel-1');
      expect(readState?.lastMessageId, ackId);
      expect(readState?.manual, isTrue);
      expect(adapter.ackedMessageIds, isEmpty);

      await notifier.markCurrentChannelRead();
      await _flushAsync();

      readState = await db.readStateDao.getReadState('channel-1');
      expect(readState?.lastMessageId, latestId);
      expect(readState?.manual, isFalse);
      expect(adapter.ackedMessageIds, [latestId]);
    },
  );
}

ProviderContainer _container(
  FluxerDatabase db,
  _ChatAdapter adapter, {
  bool foreground = true,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.fluxer.app/v1'))
    ..httpClientAdapter = adapter;
  return ProviderContainer(
    overrides: [
      fluxerDatabaseProvider.overrideWithValue(db),
      appUiForegroundProvider.overrideWithValue(foreground),
      fluxerDioProvider.overrideWithValue(dio),
      fluxerClientProvider.overrideWithValue(
        FluxerClient(dio, baseUrl: 'https://api.fluxer.app/v1'),
      ),
      currentUserIdProvider.overrideWithValue('me'),
    ],
  );
}

Future<void> _flushAsync() async {
  for (var i = 0; i < 8; i++) {
    await pumpEventQueue();
  }
}

class _ChatAdapter implements HttpClientAdapter {
  _ChatAdapter({
    required this.initialMessages,
    this.messagesAfterAck = const [],
  });

  final List<Map<String, Object?>> initialMessages;
  final List<Map<String, Object?>> messagesAfterAck;
  final List<Uri> messageRequestUris = [];
  final List<String> afterQueries = [];
  final List<String> ackedMessageIds = [];
  int failAckAttempts = 0;
  int ackAttempts = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.method == 'GET' &&
        options.uri.path.endsWith('/channels/channel-1/messages')) {
      messageRequestUris.add(options.uri);
      final after = options.uri.queryParameters['after'];
      if (after != null) {
        afterQueries.add(after);
      }
      final messages = after == null ? initialMessages : messagesAfterAck;
      return ResponseBody.fromString(
        jsonEncode(messages),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }

    if (options.method == 'POST' && options.uri.path.endsWith('/ack')) {
      ackAttempts++;
      if (failAckAttempts > 0) {
        failAckAttempts--;
        return ResponseBody.fromString('failed', 500);
      }
      ackedMessageIds.add(options.uri.pathSegments[4]);
      return ResponseBody.fromString('', 204, statusMessage: 'No Content');
    }

    return ResponseBody.fromString('Not found', 404);
  }

  @override
  void close({bool force = false}) {}
}
