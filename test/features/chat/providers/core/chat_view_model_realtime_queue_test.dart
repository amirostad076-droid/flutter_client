/// The ordered realtime apply queue.
///
/// Every mutation of `state.messages` that originates from the gateway is a
/// queue item, and so is the commit half of a wholesale window replacement.
/// These tests drive the hard interleavings through public behaviour only
/// (`switchChannel`, `loadMore`, `jumpToLatestMessages`, the realtime bus) plus
/// one seam: a message DAO that parks `getMessage` on a completer, which is the
/// database await `_nextMessagesFor` performs for the `MessageUpdated` fallback
/// and for `MessageReactionsChanged`. Parking there suspends a reducer exactly
/// where a real one suspends, so a swap, a batch or another event can be
/// ingested while it is mid-flight.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/database/daos/message_dao.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/core/providers/app_ui_lifecycle_provider.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/providers/gateway_session_recovery_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/features/channels/data/ack_batcher.dart';
import 'package:fluxer_app/features/channels/data/read_state_utils.dart';
import 'package:fluxer_app/features/channels/providers/ack_batcher_provider.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/providers/core/chat_read_viewport_provider.dart';
import 'package:fluxer_app/features/chat/providers/core/chat_view_model.dart';
import 'package:fluxer_app/features/chat/providers/messages/message_realtime_events.dart';
import 'package:fluxer_app/features/chat/providers/messages/message_realtime_provider.dart';
import 'package:fluxer_app/shared/services/guild_member_hydration_service.dart';
import 'package:fluxer_app/shared/utils/snowflake_time.dart';
import 'package:fluxer_dart/export.dart';
import 'package:fluxer_dart/gateway.dart';

import '../../../../helpers/message_realtime_test_helpers.dart';
import '../../../../helpers/noop_guild_member_hydration_service.dart';

const int _kMinuteMs = 60 * 1000;
const String _channelId = 'channel-1';
const String _otherChannelId = 'channel-2';

String _snowflakeForIndex(int index) {
  final int millis =
      DateTime.utc(2026).millisecondsSinceEpoch + index * _kMinuteMs;
  final int internal = (millis - kSnowflakeEpochMs) << 22;
  return internal.toString();
}

const String _kAttachmentId = 'attachment-1';
const String _kAttachmentId2 = 'attachment-2';

Map<String, Object?> _messageJson({
  required String id,
  required String channelId,
  required String authorId,
  String? content,
  String? nonce,
  bool withAttachment = false,
  bool secondAttachment = false,
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
  'tts': false,
  'content': content ?? 'message $id',
  'timestamp': dateTimeFromUserSnowflakeOrNull(id)!.toIso8601String(),
  'pinned': false,
  'mention_everyone': false,
  'mentions': <Object?>[],
  'mention_roles': <Object?>[],
  'nonce': nonce,
  if (withAttachment)
    'attachments': <Map<String, Object?>>[
      if (secondAttachment)
        <String, Object?>{
          'id': _kAttachmentId2,
          'filename': 'doc.pdf',
          'size': 2048,
          'flags': 0,
          'url': 'https://cdn.fluxer.app/doc.pdf',
          'proxy_url': 'https://cdn.fluxer.app/doc.pdf',
          'content_type': 'application/pdf',
          'description': null,
        },
      <String, Object?>{
        'id': _kAttachmentId,
        'filename': 'pic.png',
        'size': 1024,
        'flags': 0,
        'url': 'https://cdn.fluxer.app/pic.png',
        'proxy_url': 'https://cdn.fluxer.app/pic.png',
        'content_type': 'image/png',
        'description': null,
      },
    ],
};

List<Map<String, Object?>> _channelMessages(
  int count, {
  int? attachmentAt,
  bool twoAttachments = false,
}) => [
  for (var i = 0; i < count; i++)
    _messageJson(
      id: _snowflakeForIndex(i),
      channelId: _channelId,
      authorId: 'other',
      withAttachment: i == attachmentAt,
      secondAttachment: twoAttachments,
    ),
];

void _emitCreated(ProviderContainer container, {required String id}) {
  container
      .read(messageRealtimeBusProvider)
      .emit(
        testMessageCreated(
          MessageCreateEvent(
            message: MessageResponseSchema.fromJson(
              _messageJson(id: id, channelId: _channelId, authorId: 'other'),
            ),
          ),
          snapshot: const MessagePersistSnapshot(
            mentionsCurrentUser: false,
            isDm: false,
            guildStorageId: null,
            acknowledgedByGateway: true,
          ),
        ),
      );
}

/// Reaction changes always re-read the row from the database, which is the
/// park point these tests use.
void _emitReactions(ProviderContainer container, {required String id}) {
  container
      .read(messageRealtimeBusProvider)
      .emit(MessageReactionsChanged(channelId: _channelId, messageId: id));
}

void _emitDeleted(ProviderContainer container, {required String id}) {
  container
      .read(messageRealtimeBusProvider)
      .emit(
        MessageDeleted(
          MessageDeleteEvent(channelId: _channelId, messageId: id),
        ),
      );
}

/// Edits for a message that IS in the window take the event's payload and never
/// touch the database, so they carry content the DAO gate cannot forge.
void _emitUpdated(
  ProviderContainer container, {
  required String id,
  required String content,
}) {
  final Map<String, Object?> json = _messageJson(
    id: id,
    channelId: _channelId,
    authorId: 'other',
  )..['content'] = content;
  container
      .read(messageRealtimeBusProvider)
      .emit(
        MessageUpdated(
          MessageUpdateEvent(message: MessageResponseSchema.fromJson(json)),
        ),
      );
}

String _contentOf(ProviderContainer container, String id) => container
    .read(chatViewModelProvider)
    .messages
    .firstWhere((Message m) => m.id == id)
    .content;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MessageDaoGate gate;

  Future<_GatedDatabase> seedChannel({
    String guildId = 'guild-1',
    String? lastMessageId,
  }) async {
    gate = _MessageDaoGate();
    final _GatedDatabase database = _GatedDatabase(
      NativeDatabase.memory(),
      gate,
    );
    addTearDown(database.close);
    await database.channelDao.upsertChannel(
      db.ChannelsCompanion(
        id: const Value(_channelId),
        guildId: Value(guildId),
        name: const Value('general'),
        lastMessageId: Value(lastMessageId),
      ),
    );
    await database.channelDao.upsertChannel(
      db.ChannelsCompanion(
        id: const Value(_otherChannelId),
        guildId: Value(guildId),
        name: const Value('other'),
      ),
    );
    return database;
  }

  /// Opens the channel, then pages backwards until the window is detached from
  /// the live tail, which is the state a jump to latest replaces wholesale.
  Future<void> detachWindow(ChatViewModel notifier, ProviderContainer c) async {
    await notifier.switchChannel(_channelId);
    await _flushAsync();
    for (var i = 0; i < 8; i++) {
      if (c.read(chatViewModelProvider).hasMoreNewerMessages) {
        return;
      }
      await notifier.loadMore();
      await _flushAsync();
    }
    fail('window never detached from the live tail');
  }

  test('m1: a swap cannot commit while a reducer is parked in the '
      'database', () async {
    // The commit half of a window replacement is a QUEUE ITEM. A reducer that
    // is parked in its database read therefore holds the commit off, instead of
    // the two writing over each other in whichever order the event loop picks.
    final _GatedDatabase database = await seedChannel();
    final adapter = _MessageApiAdapter(messages: _channelMessages(400));
    final container = _container(database, adapter);
    addTearDown(container.dispose);

    final notifier = container.read(chatViewModelProvider.notifier);
    await detachWindow(notifier, container);

    final String tailId = _snowflakeForIndex(399);
    gate.hold(tailId, content: 'reacted');

    final List<String> detached = container
        .read(chatViewModelProvider)
        .messages
        .map((Message m) => m.id)
        .toList();
    expect(detached, isNot(contains(tailId)));

    _emitReactions(container, id: tailId);
    await _flushAsync();
    expect(
      gate.outstanding,
      1,
      reason: 'the reducer must be parked inside the database read',
    );

    var jumpSettled = false;
    final Future<bool> jump = notifier.jumpToLatestMessages().whenComplete(() {
      jumpSettled = true;
    });
    // The REST page resolves inside this flush; only the COMMIT is blocked.
    await _flushAsync();

    expect(
      container.read(chatViewModelProvider).messages.map((Message m) => m.id),
      detached,
      reason:
          'the wholesale write must wait for the parked reducer, not race it',
    );
    expect(jumpSettled, isFalse, reason: 'the swap has not committed yet');

    gate.releaseAll();
    expect(await jump, isTrue);
    await _flushAsync();

    final state = container.read(chatViewModelProvider);
    expect(state.messages.last.id, tailId, reason: 'the new window survives');
    expect(state.hasMoreNewerMessages, isFalse);
    expect(
      _contentOf(container, tailId),
      'reacted',
      reason: 'the parked event replays onto the window the swap installed',
    );
  });

  test('m3: an event parked before the arm survives into the post swap '
      'window', () async {
    // The reducer entered before there was any swap to notice, so nothing
    // captured it on the way in. It resumes owing the queue a decision: writing
    // onto the window the swap is about to replace loses it outright.
    final _GatedDatabase database = await seedChannel();
    final adapter = _MessageApiAdapter(messages: _channelMessages(400));
    final container = _container(database, adapter);
    addTearDown(container.dispose);

    final notifier = container.read(chatViewModelProvider.notifier);
    await detachWindow(notifier, container);

    final String tailId = _snowflakeForIndex(399);
    gate.hold(tailId, content: 'reacted');

    _emitReactions(container, id: tailId);
    await _flushAsync();
    expect(gate.outstanding, 1);

    // Arm, and keep the page in flight so the reducer is released strictly
    // BEFORE the swap has anything to write.
    adapter.holdLatestFetch = true;
    final Future<bool> jump = notifier.jumpToLatestMessages();
    await _flushAsync();

    gate.releaseAll();
    await _flushAsync();

    adapter.releaseLatestFetch();
    expect(await jump, isTrue);
    await _flushAsync();

    expect(
      container.read(chatViewModelProvider).messages.last.id,
      tailId,
      reason: 'the swap still installs its window',
    );
    expect(
      _contentOf(container, tailId),
      'reacted',
      reason: 'an event that straddled the arm must not be dropped',
    );
  });

  test('m-order: a straddling event replays before events that arrived '
      'after the arm', () async {
    // The straddler is older than everything the swap held, so it goes back on
    // the queue AT ITS OWN ORDINAL rather than at either end of the list.
    // Resolving the two in the wrong order leaves the earlier revision winning.
    final _GatedDatabase database = await seedChannel();
    final adapter = _MessageApiAdapter(messages: _channelMessages(400));
    final container = _container(database, adapter);
    addTearDown(container.dispose);

    final notifier = container.read(chatViewModelProvider.notifier);
    await detachWindow(notifier, container);

    final String tailId = _snowflakeForIndex(399);
    gate.hold(tailId, content: 'reacted');

    // A: arrives first, parks in the database read, straddles the arm.
    _emitReactions(container, id: tailId);
    await _flushAsync();
    expect(gate.outstanding, 1);

    adapter.holdLatestFetch = true;
    final Future<bool> jump = notifier.jumpToLatestMessages();
    await _flushAsync();

    // B: arrives after the arm, so it is strictly newer than A and must win.
    // Its content comes from the event payload, not from the database, so the
    // two are distinguishable no matter how the DAO answers.
    _emitUpdated(container, id: tailId, content: 'edited');
    await _flushAsync();

    gate.releaseAll();
    await _flushAsync();
    adapter.releaseLatestFetch();
    expect(await jump, isTrue);
    await _flushAsync();

    expect(
      _contentOf(container, tailId),
      'edited',
      reason: 'the later event must be applied last, not first',
    );
  });

  test('m4: a coalesced create batch held by a swap lands in order on the '
      'new window', () async {
    // The batch computes its list from a snapshot and writes once at the end.
    // Running it against the window the swap is replacing throws away every
    // create in it, because a detached window refuses live creates outright.
    final _GatedDatabase database = await seedChannel();
    final adapter = _MessageApiAdapter(messages: _channelMessages(400));
    final container = _container(database, adapter);
    addTearDown(container.dispose);

    final notifier = container.read(chatViewModelProvider.notifier);
    await detachWindow(notifier, container);

    final String tailId = _snowflakeForIndex(399);
    gate.hold(tailId, content: 'reacted');

    _emitReactions(container, id: tailId);
    await _flushAsync();
    expect(gate.outstanding, 1);

    final List<String> created = <String>[
      _snowflakeForIndex(500),
      _snowflakeForIndex(501),
      _snowflakeForIndex(502),
    ];
    for (final String id in created) {
      _emitCreated(container, id: id);
    }

    final Future<bool> jump = notifier.jumpToLatestMessages();
    await _flushAsync();

    gate.releaseAll();
    expect(await jump, isTrue);
    await _flushAsync();

    final List<String> ids = container
        .read(chatViewModelProvider)
        .messages
        .map((Message m) => m.id)
        .toList();
    expect(
      ids.contains(_snowflakeForIndex(350)),
      isTrue,
      reason: 'the window the swap fetched survives',
    );
    expect(
      ids.sublist(ids.length - 3),
      created,
      reason: 'every batched create lands, in arrival order, on the new window',
    );
    expect(_contentOf(container, tailId), 'reacted');
  });

  test('m5: overlapping live applications all survive in ingress '
      'order', () async {
    // No swap anywhere. A reducer parks in its database read and two coalesced
    // create batches plus a later edit are ingested behind it. Unserialised,
    // all three run over the parked reducer and the reducer then resumes and
    // writes its own older revision over the edit: the LAST event to arrive is
    // the one that disappears.
    final _GatedDatabase database = await seedChannel();
    final adapter = _MessageApiAdapter(messages: _channelMessages(20));
    final container = _container(database, adapter);
    addTearDown(container.dispose);

    final notifier = container.read(chatViewModelProvider.notifier);
    await notifier.switchChannel(_channelId);
    await _flushAsync();

    final String target = _snowflakeForIndex(18);
    gate.hold(target, content: 'reacted');

    final List<String> created = <String>[
      _snowflakeForIndex(100),
      _snowflakeForIndex(101),
      _snowflakeForIndex(102),
      _snowflakeForIndex(103),
    ];
    // A non-create flushes the buffered creates on the spot, so this is four
    // separate applications: a batch, the parking reducer, a second batch and
    // an edit whose payload needs no database read at all.
    _emitCreated(container, id: created[0]);
    _emitCreated(container, id: created[1]);
    _emitReactions(container, id: target);
    _emitCreated(container, id: created[2]);
    _emitCreated(container, id: created[3]);
    _emitUpdated(container, id: target, content: 'edited');

    await _flushAsync();

    // Anti-vacuity: everything after the reaction really was ingested while the
    // reaction sat parked, and the queue held all of it behind that reducer.
    expect(
      gate.outstanding,
      1,
      reason: 'the first application must still be parked here',
    );
    final List<String> midFlight = container
        .read(chatViewModelProvider)
        .messages
        .map((Message m) => m.id)
        .toList();
    expect(
      midFlight,
      containsAll(<String>[created[0], created[1]]),
      reason: 'the batch ahead of the parked reducer already applied',
    );
    expect(
      midFlight,
      isNot(contains(created[2])),
      reason: 'the batch behind the parked reducer must not write yet',
    );
    expect(
      _contentOf(container, target),
      isNot('edited'),
      reason: 'the edit behind the parked reducer must not write yet',
    );

    gate.releaseAll();
    await _flushAsync();

    final List<String> ids = container
        .read(chatViewModelProvider)
        .messages
        .map((Message m) => m.id)
        .toList();
    expect(
      ids.sublist(ids.length - 4),
      created,
      reason: "no application may lose another one's creates",
    );
    expect(
      _contentOf(container, target),
      'edited',
      reason: 'the last event to arrive must be the last one applied',
    );
  });

  test('m6: a write from outside the queue is not erased by a parked '
      'reducer', () async {
    // state.messages has writers the queue does not own: pagination, optimistic
    // sends, edits and deletes. A queued reducer must therefore commit a list
    // derived from state as it is when the reducer WRITES, not as it was when
    // the reducer entered, or the user's own message disappears the moment a
    // reaction happens to be parked in its database read.
    final String sentId = _snowflakeForIndex(200);
    final _GatedDatabase database = await seedChannel(guildId: '');
    final adapter = _MessageApiAdapter(
      messages: _channelMessages(20),
      sentMessageId: sentId,
    );
    final container = _container(database, adapter);
    addTearDown(container.dispose);

    final notifier = container.read(chatViewModelProvider.notifier);
    await notifier.switchChannel(_channelId);
    await _flushAsync();

    final String target = _snowflakeForIndex(19);
    gate.hold(target, content: 'reacted');

    _emitReactions(container, id: target);
    await _flushAsync();
    expect(
      gate.outstanding,
      1,
      reason: 'the reducer must be parked inside the database read',
    );

    // A writer the queue does not own, landing squarely inside the park.
    await notifier.sendMessage(text: 'hello from me');
    await _flushAsync();

    expect(
      gate.outstanding,
      1,
      reason: 'the send must have landed while the reducer was still parked',
    );
    expect(
      container.read(chatViewModelProvider).messages.map((Message m) => m.id),
      contains(sentId),
      reason: 'the send is applied immediately, it does not wait on the queue',
    );
    expect(_contentOf(container, target), isNot('reacted'));

    gate.releaseAll();
    await _flushAsync();

    final state = container.read(chatViewModelProvider);
    expect(
      state.messages.map((Message m) => m.id),
      contains(sentId),
      reason: 'the reducer must not commit a base that predates the send',
    );
    expect(
      state.messages.last.id,
      sentId,
      reason: 'the sent message keeps its place at the tail',
    );
    expect(
      _contentOf(container, target),
      'reacted',
      reason: 'the reduced event still lands',
    );
  });

  test('m6-batch: a coalesced create batch commits against the window as it '
      'is when it writes', () async {
    // The batch path is the one that used to carry a base across awaits, and
    // the reason it looked safe was that the create reducer touches no
    // database. That is an invariant nothing enforced. Gate the message DAO on
    // the batch's own ids: the shipped batch never reads it and commits
    // atomically, while any batch that reduces against a carried base parks
    // mid-loop right here, lets the send land, and then erases it.
    final String sentId = _snowflakeForIndex(300);
    final _GatedDatabase database = await seedChannel(guildId: '');
    final adapter = _MessageApiAdapter(
      messages: _channelMessages(20),
      sentMessageId: sentId,
    );
    final container = _container(database, adapter);
    addTearDown(container.dispose);

    final notifier = container.read(chatViewModelProvider.notifier);
    await notifier.switchChannel(_channelId);
    await _flushAsync();

    final List<String> created = <String>[
      for (var i = 0; i < 4; i++) _snowflakeForIndex(100 + i),
    ];
    for (final String id in created) {
      gate.hold(id, content: 'unused');
    }

    for (final String id in created) {
      _emitCreated(container, id: id);
    }
    await _flushAsync();

    // A writer the queue does not own, landing while the batch is between
    // creates for anything that reduces against a carried base.
    await notifier.sendMessage(text: 'hello from me');
    await _flushAsync();

    gate.releaseAll();
    await _flushAsync();

    final List<String> ids = container
        .read(chatViewModelProvider)
        .messages
        .map((Message m) => m.id)
        .toList();
    expect(
      ids,
      contains(sentId),
      reason: 'the batch must not commit a base that predates the send',
    );
    expect(
      ids.where(created.contains).toList(),
      created,
      reason: 'every batched create lands, in arrival order',
    );
  });

  test('m7: clearing a swap barrier wakes the queue on its own', () async {
    // The worker returns the instant a swap arms, so everything enqueued during
    // the swap sits in the queue with nobody running. Clearing the barrier is
    // the eligibility transition that has to wake it: a swap that dies without
    // committing must not leave its events stranded until unrelated later
    // traffic happens to pump the queue.
    final _GatedDatabase database = await seedChannel();
    final adapter = _MessageApiAdapter(messages: _channelMessages(400));
    final container = _container(database, adapter);
    addTearDown(container.dispose);

    final notifier = container.read(chatViewModelProvider.notifier);
    await detachWindow(notifier, container);

    adapter
      ..holdLatestFetch = true
      ..failLatestFetch = true;
    final Future<bool> jump = notifier.jumpToLatestMessages();
    await _flushAsync();

    // A message that is IN the detached window, edited by an event whose
    // payload needs no database read: the reduction is pure, so the only thing
    // this test can fail on is the wakeup.
    final String target = container
        .read(chatViewModelProvider)
        .messages
        .last
        .id;
    _emitUpdated(container, id: target, content: 'woken');
    await _flushAsync();

    expect(
      _contentOf(container, target),
      isNot('woken'),
      reason: 'the barrier holds the event while the swap owns the channel',
    );

    // The swap dies here: its page fails, so it disarms without ever
    // committing. NOTHING is emitted after this point, so only the disarm
    // itself can get the queue moving again.
    adapter.releaseLatestFetch();
    expect(await jump, isFalse);

    expect(
      _contentOf(container, target),
      'woken',
      reason: 'clearing the barrier must wake the queue with no new traffic',
    );
  });

  test('m8: a swap superseded while its commit waits in the lane never '
      'writes', () async {
    // A commit is validated where it is ENQUEUED, but it runs later, behind
    // whatever reducer was mid application. A newer jump can arm in that gap.
    // Executing the older commit anyway installs the page for a message the
    // user has already navigated away from, scrolls to it, and if the newer
    // swap then dies and disarms, that stale window is what sticks.
    final _GatedDatabase database = await seedChannel();
    final adapter = _MessageApiAdapter(messages: _channelMessages(400));
    final container = _container(database, adapter);
    addTearDown(container.dispose);

    final notifier = container.read(chatViewModelProvider.notifier);
    await notifier.switchChannel(_channelId);
    await _flushAsync();

    // Far apart, so the two around-windows are disjoint from each other and
    // from the tail window the channel opened on.
    final String targetA = _snowflakeForIndex(50);
    final String targetB = _snowflakeForIndex(300);

    // Transient states matter here: asserting only the final window would miss
    // a superseded write that lands and is then overwritten by the winner.
    var sawWindowA = false;
    container.listen<List<Message>>(
      chatViewModelProvider.select((ChatViewState s) => s.messages),
      (List<Message>? previous, List<Message> next) {
        if (next.any((Message m) => m.id == targetA)) {
          sawWindowA = true;
        }
      },
    );
    final List<String> scrolled = <String>[];
    container.listen<(String, int)?>(
      chatViewModelProvider.select(
        (ChatViewState s) => s.scrollToMessageSignal,
      ),
      (_, (String, int)? next) {
        if (next != null) {
          scrolled.add(next.$1);
        }
      },
    );

    // Park the worker so any commit has to queue behind it.
    final String parked = container
        .read(chatViewModelProvider)
        .messages
        .last
        .id;
    gate.hold(parked, content: 'reacted');
    _emitReactions(container, id: parked);
    await _flushAsync();
    expect(gate.outstanding, 1, reason: 'the worker must be parked');

    // A runs to the point of committing, and its commit lands in the lane.
    final Future<void> jumpA = notifier.goToRepliedMessage(
      messageId: targetA,
      channelId: _channelId,
    );
    await _flushAsync();
    expect(
      gate.outstanding,
      1,
      reason: 'the reducer is still parked, so A cannot have committed',
    );
    expect(sawWindowA, isFalse, reason: "A's commit is queued, not applied");

    // B supersedes A: generation bump plus a fresh arm, all while the worker is
    // still parked and A's commit is still waiting.
    final Future<void> jumpB = notifier.goToRepliedMessage(
      messageId: targetB,
      channelId: _channelId,
    );
    await _flushAsync();
    expect(
      gate.outstanding,
      1,
      reason: 'supersession happened before anything was released',
    );

    gate.releaseAll();
    await jumpA;
    await jumpB;
    await _flushAsync();

    expect(
      sawWindowA,
      isFalse,
      reason: "the superseded swap's page must never become the window",
    );
    expect(
      scrolled,
      isNot(contains(targetA)),
      reason: 'the user must not be scrolled to the target they left',
    );
    final ChatViewState state = container.read(chatViewModelProvider);
    expect(
      state.messages.map((Message m) => m.id),
      contains(targetB),
      reason: 'the winning jump still lands normally',
    );
    expect(scrolled.last, targetB);
  });

  test('m8b: a no-load channel switch supersedes a queued commit without '
      'ever arming', () async {
    // switchChannel bumps the switch generation unconditionally, but its
    // loadMessages:false branch writes the new channel's state directly and
    // returns without arming anything. A commit queued before it therefore
    // still holds the armed token: a token-only gate lets it through and it
    // wholesale-writes channel-1's page into the channel the user just opened.
    final _GatedDatabase database = await seedChannel();
    final adapter = _MessageApiAdapter(messages: _channelMessages(400));
    final container = _container(database, adapter);
    addTearDown(container.dispose);

    final notifier = container.read(chatViewModelProvider.notifier);
    await notifier.switchChannel(_channelId);
    await _flushAsync();

    final String targetA = _snowflakeForIndex(50);
    var sawWindowA = false;
    container.listen<List<Message>>(
      chatViewModelProvider.select((ChatViewState s) => s.messages),
      (List<Message>? previous, List<Message> next) {
        if (next.any((Message m) => m.id == targetA)) {
          sawWindowA = true;
        }
      },
    );
    final List<String> scrolled = <String>[];
    container.listen<(String, int)?>(
      chatViewModelProvider.select(
        (ChatViewState s) => s.scrollToMessageSignal,
      ),
      (_, (String, int)? next) {
        if (next != null) {
          scrolled.add(next.$1);
        }
      },
    );

    final String parked = container
        .read(chatViewModelProvider)
        .messages
        .last
        .id;
    gate.hold(parked, content: 'reacted');
    _emitReactions(container, id: parked);
    await _flushAsync();
    expect(gate.outstanding, 1, reason: 'the worker must be parked');

    final Future<void> jumpA = notifier.goToRepliedMessage(
      messageId: targetA,
      channelId: _channelId,
    );
    await _flushAsync();
    expect(gate.outstanding, 1, reason: "A's commit is queued, not applied");
    expect(sawWindowA, isFalse);

    // Supersede with NO arm at all.
    await notifier.switchChannel(_otherChannelId, loadMessages: false);
    await _flushAsync();
    expect(container.read(chatViewModelProvider).channelId, _otherChannelId);
    expect(gate.outstanding, 1, reason: 'nothing was released yet');

    gate.releaseAll();
    await jumpA;
    await _flushAsync();

    final ChatViewState state = container.read(chatViewModelProvider);
    expect(
      sawWindowA,
      isFalse,
      reason:
          'the superseded page must never reach the channel the user '
          'switched to',
    );
    expect(state.channelId, _otherChannelId);
    expect(
      state.messages,
      isEmpty,
      reason: 'the new channel loaded nothing and must stay empty',
    );
    expect(scrolled, isNot(contains(targetA)));
    expect(state.isLoading, isFalse);
    expect(state.isSyncingMessages, isFalse);
  });

  test(
    'm8c: a same-channel no-load switch supersedes a queued commit',
    () async {
      // The channel id never changes here, so a channel check cannot see it
      // either. Only the caller's own generation predicate can.
      final _GatedDatabase database = await seedChannel();
      final adapter = _MessageApiAdapter(messages: _channelMessages(400));
      final container = _container(database, adapter);
      addTearDown(container.dispose);

      final notifier = container.read(chatViewModelProvider.notifier);
      await notifier.switchChannel(_channelId);
      await _flushAsync();

      final String targetA = _snowflakeForIndex(50);
      var sawWindowA = false;
      container.listen<List<Message>>(
        chatViewModelProvider.select((ChatViewState s) => s.messages),
        (List<Message>? previous, List<Message> next) {
          if (next.any((Message m) => m.id == targetA)) {
            sawWindowA = true;
          }
        },
      );

      final List<String> before = container
          .read(chatViewModelProvider)
          .messages
          .map((Message m) => m.id)
          .toList();
      gate.hold(before.last, content: 'reacted');
      _emitReactions(container, id: before.last);
      await _flushAsync();
      expect(gate.outstanding, 1);

      final Future<void> jumpA = notifier.goToRepliedMessage(
        messageId: targetA,
        channelId: _channelId,
      );
      await _flushAsync();
      expect(sawWindowA, isFalse);

      await notifier.switchChannel(_channelId, loadMessages: false);
      await _flushAsync();
      expect(container.read(chatViewModelProvider).channelId, _channelId);

      gate.releaseAll();
      await jumpA;
      await _flushAsync();

      expect(
        sawWindowA,
        isFalse,
        reason:
            'a swap superseded by user intent must not land, even when the '
            'channel id is unchanged',
      );
      expect(
        container.read(chatViewModelProvider).messages.map((Message m) => m.id),
        before,
        reason: 'the no-load switch kept the window it had',
      );
    },
  );

  test('m9: supersession between the commit and the caller resuming blocks '
      'the post-commit effects', () async {
    // The commit's own write is what wakes the superseding intent here: the
    // state listener fires before the awaiting caller resumes, so the switch
    // generation moves in the microtask BETWEEN commit.done completing and
    // jumpToLatestMessages continuing. applied is already true and stale.
    final _GatedDatabase database = await seedChannel();
    final adapter = _MessageApiAdapter(messages: _channelMessages(400));
    final container = _container(database, adapter);
    addTearDown(container.dispose);

    final notifier = container.read(chatViewModelProvider.notifier);
    await detachWindow(notifier, container);

    final String tailId = _snowflakeForIndex(399);
    var superseded = false;
    container.listen<List<Message>>(
      chatViewModelProvider.select((ChatViewState s) => s.messages),
      (List<Message>? previous, List<Message> next) {
        if (!superseded && next.any((Message m) => m.id == tailId)) {
          superseded = true;
          // Real API, no test hook: this bumps the switch generation
          // synchronously, before its first await.
          unawaited(
            notifier.switchChannel(_otherChannelId, loadMessages: false),
          );
        }
      },
    );

    final int scrollBefore = container
        .read(chatViewModelProvider)
        .scrollToBottomSignal;

    final bool ok = await notifier.jumpToLatestMessages();
    await _flushAsync();

    expect(
      superseded,
      isTrue,
      reason: 'the supersession must actually have fired, or this is vacuous',
    );
    expect(
      ok,
      isFalse,
      reason: 'a jump superseded before it resumed must not report success',
    );
    expect(
      container.read(chatViewModelProvider).scrollToBottomSignal,
      scrollBefore,
      reason: 'no scroll may fire for a window the user has already left',
    );
  });

  test('m10: a commit waiting in the lane does not erase a send that '
      'lands while it waits', () async {
    // The payload twin of the validity work. The commit is entirely legitimate
    // when it runs: token current, generation current, channel current. Its
    // DATA is what is stale, because the merge against local state ran before
    // the lane wait and the user sent a message during it.
    final String sentId = _snowflakeForIndex(500);
    final _GatedDatabase database = await seedChannel(guildId: '');
    final adapter = _MessageApiAdapter(
      messages: _channelMessages(400),
      sentMessageId: sentId,
    );
    final container = _container(database, adapter);
    addTearDown(container.dispose);

    final notifier = container.read(chatViewModelProvider.notifier);
    await detachWindow(notifier, container);

    final String parked = container
        .read(chatViewModelProvider)
        .messages
        .last
        .id;
    gate.hold(parked, content: 'reacted');
    _emitReactions(container, id: parked);
    await _flushAsync();
    expect(gate.outstanding, 1, reason: 'the worker must be parked');

    var jumpSettled = false;
    final Future<bool> jump = notifier.jumpToLatestMessages().whenComplete(() {
      jumpSettled = true;
    });
    await _flushAsync();
    expect(jumpSettled, isFalse, reason: 'the commit is waiting in the lane');

    // Held open so the row is still an unsent local message at write time,
    // which is exactly the shape the merge is supposed to preserve.
    adapter.holdSend = true;
    final Future<void> send = notifier.sendMessage(text: 'hello from me');
    await _flushAsync();
    final Message optimistic = container
        .read(chatViewModelProvider)
        .messages
        .lastWhere((Message m) => m.content == 'hello from me');
    expect(gate.outstanding, 1, reason: 'the send landed during the lane wait');

    gate.releaseAll();
    expect(await jump, isTrue);
    await _flushAsync();

    expect(
      container.read(chatViewModelProvider).messages.map((Message m) => m.id),
      contains(optimistic.id),
      reason:
          'the commit must compose its list from the window as it is when '
          'it writes, not as it was before it queued',
    );

    adapter.releaseSend();
    await send;
    await _flushAsync();
  });

  test('m10b: a commit does not resurrect a message deleted while it '
      'waited', () async {
    // A pending delete has no representation a fresh read can recover: the row
    // is simply absent, and the page, fetched before the server saw the delete,
    // puts it straight back. Only the pending-mutation overlay catches this.
    final _GatedDatabase database = await seedChannel();
    final adapter = _MessageApiAdapter(messages: _channelMessages(400));
    final container = _container(database, adapter);
    addTearDown(container.dispose);

    final notifier = container.read(chatViewModelProvider.notifier);
    await detachWindow(notifier, container);

    final String parked = container
        .read(chatViewModelProvider)
        .messages
        .last
        .id;
    gate.hold(parked, content: 'reacted');
    _emitReactions(container, id: parked);
    await _flushAsync();

    // In the tail page the jump is about to install, not in the detached
    // window: the page is the only thing that can put it on screen.
    final String deletedId = _snowflakeForIndex(399);
    final Future<bool> jump = notifier.jumpToLatestMessages();
    await _flushAsync();

    adapter.holdDelete = true;
    final Future<void> deletion = notifier.deleteMessage(deletedId);
    await _flushAsync();

    gate.releaseAll();
    expect(await jump, isTrue);
    await _flushAsync();

    expect(
      container.read(chatViewModelProvider).messages.map((Message m) => m.id),
      isNot(contains(deletedId)),
      reason: 'a page fetched before the delete must not resurrect the row',
    );

    // Cleanup: once the request settles the overlay entry must go, or the
    // message is hidden forever. Jumping to the very id that was filtered out
    // isolates the overlay: the fake server still serves it, so the only thing
    // that can keep it off screen now is a leaked tombstone.
    adapter.releaseDelete();
    await deletion;
    await _flushAsync();
    await notifier.goToRepliedMessage(
      messageId: deletedId,
      channelId: _channelId,
    );
    await _flushAsync();
    expect(
      container.read(chatViewModelProvider).messages.map((Message m) => m.id),
      contains(deletedId),
      reason: 'a settled delete must not leave a tombstone behind',
    );
  });

  test('m10b-ack: a completed delete still beats an older page in the '
      'lane', () async {
    // The sharpened case. The delete is SERVER CONFIRMED before the queued
    // commit ever runs, so anything that retires the tombstone at request
    // completion consults an empty log and lets the older page reinstate a
    // message the server has already deleted.
    final _GatedDatabase database = await seedChannel();
    final adapter = _MessageApiAdapter(messages: _channelMessages(400));
    final container = _container(database, adapter);
    addTearDown(container.dispose);

    final notifier = container.read(chatViewModelProvider.notifier);
    await detachWindow(notifier, container);

    final String parked = container
        .read(chatViewModelProvider)
        .messages
        .last
        .id;
    gate.hold(parked, content: 'reacted');
    _emitReactions(container, id: parked);
    await _flushAsync();

    final String deletedId = _snowflakeForIndex(399);
    final Future<bool> jump = notifier.jumpToLatestMessages();
    await _flushAsync();

    // Starts AND finishes while the commit waits in the lane.
    await notifier.deleteMessage(deletedId);
    await _flushAsync();

    gate.releaseAll();
    expect(await jump, isTrue);
    await _flushAsync();

    expect(
      container.read(chatViewModelProvider).messages.map((Message m) => m.id),
      isNot(contains(deletedId)),
      reason:
          'a confirmed delete must outlive its own request while an older '
          'page is still queued',
    );
  });

  test('m10e: a delete acknowledged after a later fetch started still '
      'wins', () async {
    // Client start order cannot order server visibility. The delete STARTS
    // first and is still in flight when the fetch STARTS, so a start-order
    // comparison concludes the page is newer and skips the overlay, while in
    // truth the page reached the server first and carries the pre-delete row.
    final _GatedDatabase database = await seedChannel();
    final adapter = _MessageApiAdapter(messages: _channelMessages(400));
    final container = _container(database, adapter);
    addTearDown(container.dispose);

    final notifier = container.read(chatViewModelProvider.notifier);
    await detachWindow(notifier, container);

    final String parked = container
        .read(chatViewModelProvider)
        .messages
        .last
        .id;
    gate.hold(parked, content: 'reacted');
    _emitReactions(container, id: parked);
    await _flushAsync();

    final String deletedId = _snowflakeForIndex(399);

    // 1. the mutation starts and stays pending
    adapter.holdDelete = true;
    final Future<void> deletion = notifier.deleteMessage(deletedId);
    await _flushAsync();

    // 2. the fetch starts AFTER it, and its commit queues behind the reducer
    final Future<bool> jump = notifier.jumpToLatestMessages();
    await _flushAsync();

    // 3. only now does the server acknowledge
    adapter.releaseDelete();
    await deletion;
    await _flushAsync();

    // 4. and only now does the stale page get to write
    gate.releaseAll();
    expect(await jump, isTrue);
    await _flushAsync();

    expect(
      container.read(chatViewModelProvider).messages.map((Message m) => m.id),
      isNot(contains(deletedId)),
      reason:
          'the boundary is the acknowledgement, not which of the two the '
          'client started first',
    );
  });

  test('m10c-ack: a completed edit still beats an older page in the '
      'lane', () async {
    // Edit twin of m10b-ack: the edit is server confirmed before the older
    // page commits, and retiring the revision at request completion lets the
    // page's pre-edit copy overwrite it.
    const int attachmentIndex = 352;
    final _GatedDatabase database = await seedChannel();
    final adapter = _MessageApiAdapter(
      messages: _channelMessages(400, attachmentAt: attachmentIndex),
    );
    final container = _container(database, adapter);
    addTearDown(container.dispose);

    final notifier = container.read(chatViewModelProvider.notifier);
    await notifier.switchChannel(_channelId);
    await _flushAsync();

    final String editedId = _snowflakeForIndex(attachmentIndex);
    final String parked = container
        .read(chatViewModelProvider)
        .messages
        .last
        .id;
    gate.hold(parked, content: 'reacted');
    _emitReactions(container, id: parked);
    await _flushAsync();

    final Future<void> jump = notifier.goToRepliedMessage(
      messageId: _snowflakeForIndex(340),
      channelId: _channelId,
    );
    await _flushAsync();

    // Starts AND finishes while the older page waits in the lane.
    await notifier.editAttachmentAltText(
      messageId: editedId,
      attachmentId: _kAttachmentId,
      description: 'a local description',
    );
    await _flushAsync();

    gate.releaseAll();
    await jump;
    await _flushAsync();

    final Message committed = container
        .read(chatViewModelProvider)
        .messages
        .firstWhere((Message m) => m.id == editedId);
    expect(
      committed.attachments.single.description,
      'a local description',
      reason:
          'a confirmed edit must outlive its own request while an older '
          'page is still queued',
    );
  });

  test('m10g: an overlay operation leaves fields it never touched '
      'alone', () async {
    // The page row carries a NEWER remote text edit AND the pre-delete
    // attachment. Substituting a stored whole-message revision would take the
    // attachment off correctly and revert the text along with it, because the
    // revision owns every field. The operation only owns the attachment.
    const int attachmentIndex = 352;
    final _GatedDatabase database = await seedChannel();
    final adapter = _MessageApiAdapter(
      messages: _channelMessages(400, attachmentAt: attachmentIndex),
    );
    final container = _container(database, adapter);
    addTearDown(() {
      adapter.releaseAroundFetch();
      container.dispose();
    });

    final notifier = container.read(chatViewModelProvider.notifier);
    await notifier.switchChannel(_channelId);
    await _flushAsync();

    final String editedId = _snowflakeForIndex(attachmentIndex);

    // A page whose fetch BEGINS before the acknowledgement, so the overlay is
    // in force for it, and which is served only after everything else happens.
    adapter.holdAroundFetch = true;
    final Future<void> jump = notifier.goToRepliedMessage(
      messageId: _snowflakeForIndex(340),
      channelId: _channelId,
    );
    await _flushAsync();

    await notifier.deleteMessageAttachment(
      messageId: editedId,
      attachmentId: _kAttachmentId,
    );
    await _flushAsync();

    // Somebody else edits the TEXT of the same message, server side, after our
    // attachment removal was acknowledged. The still-held page picks it up.
    adapter.messages[attachmentIndex] = _messageJson(
      id: editedId,
      channelId: _channelId,
      authorId: 'other',
      content: 'edited remotely',
      withAttachment: true,
    );
    adapter.releaseAroundFetch();
    await jump;
    await _flushAsync();

    final Message committed = container
        .read(chatViewModelProvider)
        .messages
        .firstWhere((Message m) => m.id == editedId);
    expect(
      committed.content,
      'edited remotely',
      reason: 'the overlay must not own fields the operation never touched',
    );
    expect(
      committed.attachments,
      isEmpty,
      reason: 'the operation it DID perform still applies',
    );
  });

  test('m10h: a failed edit after a channel switch does not write into the '
      'new channel', () async {
    // The request outlives the window it was issued against. An index captured
    // before the switch either points at a different row or past the end of a
    // shorter one, and restoring an old channel's message into the new channel
    // is wrong even when the index happens to be in range.
    const int attachmentIndex = 352;
    final _GatedDatabase database = await seedChannel();
    final adapter = _MessageApiAdapter(
      messages: _channelMessages(400, attachmentAt: attachmentIndex),
    );
    final container = _container(database, adapter);
    addTearDown(container.dispose);

    final notifier = container.read(chatViewModelProvider.notifier);
    await notifier.switchChannel(_channelId);
    await _flushAsync();

    final String editedId = _snowflakeForIndex(attachmentIndex);
    adapter
      ..holdEdit = true
      ..failEdit = true;
    final Future<void> edit = notifier.editAttachmentAltText(
      messageId: editedId,
      attachmentId: _kAttachmentId,
      description: 'a local description',
    );
    await _flushAsync();

    await notifier.switchChannel(_otherChannelId, loadMessages: false);
    await _flushAsync();
    expect(container.read(chatViewModelProvider).messages, isEmpty);

    adapter.releaseEdit();
    await edit;
    await _flushAsync();

    final ChatViewState state = container.read(chatViewModelProvider);
    expect(state.channelId, _otherChannelId);
    expect(
      state.messages,
      isEmpty,
      reason:
          "a rollback must not inject the old channel's message into the "
          'channel the user is now in',
    );
  });

  test('m10h-reorder: a failed edit restores by id, not by a captured '
      'index', () async {
    // Same request, same window, but the window grew underneath it. The
    // captured index now names a different message, so an index-based restore
    // overwrites that row with a copy of the edited one.
    const int attachmentIndex = 352;
    final _GatedDatabase database = await seedChannel();
    final adapter = _MessageApiAdapter(
      messages: _channelMessages(400, attachmentAt: attachmentIndex),
    );
    final container = _container(database, adapter);
    addTearDown(container.dispose);

    final notifier = container.read(chatViewModelProvider.notifier);
    await notifier.switchChannel(_channelId);
    await _flushAsync();

    final String editedId = _snowflakeForIndex(attachmentIndex);
    adapter
      ..holdEdit = true
      ..failEdit = true;
    final Future<void> edit = notifier.editAttachmentAltText(
      messageId: editedId,
      attachmentId: _kAttachmentId,
      description: 'a local description',
    );
    await _flushAsync();

    // Prepend a page: every index in the window shifts.
    await notifier.loadMore();
    await _flushAsync();

    adapter.releaseEdit();
    await edit;
    await _flushAsync();

    final List<Message> messages = container
        .read(chatViewModelProvider)
        .messages;
    expect(
      messages.where((Message m) => m.id == editedId).length,
      1,
      reason: 'restoring by a stale index duplicates the row it lands on',
    );
    final Message restored = messages.firstWhere(
      (Message m) => m.id == editedId,
    );
    expect(
      restored.attachments.single.description,
      isNull,
      reason: 'the failed edit rolled back to the server revision',
    );
    expect(
      messages.map((Message m) => m.id).toSet().length,
      messages.length,
      reason: 'no row may be overwritten by a copy of another',
    );
  });

  test('m10i: two operations on one message, both survive a page fetched '
      'between them', () async {
    // One message, two attachments, two different operations outstanding at
    // once. A log that keeps one slot per message would drop whichever lost
    // the race. They now settle in issue order, because the transport forces
    // serialisation, but both are recorded from the moment they are issued.
    const int attachmentIndex = 352;
    final _GatedDatabase database = await seedChannel();
    final adapter = _MessageApiAdapter(
      messages: _channelMessages(
        400,
        attachmentAt: attachmentIndex,
        twoAttachments: true,
      ),
    );
    final container = _container(database, adapter);
    addTearDown(() {
      adapter.releaseAroundFetch();
      container.dispose();
    });

    final notifier = container.read(chatViewModelProvider.notifier);
    await notifier.switchChannel(_channelId);
    await _flushAsync();

    final String editedId = _snowflakeForIndex(attachmentIndex);
    expect(
      container
          .read(chatViewModelProvider)
          .messages
          .firstWhere((Message m) => m.id == editedId)
          .attachments
          .length,
      2,
    );

    // A page whose fetch begins before either acknowledgement.
    adapter.holdAroundFetch = true;
    final Future<void> jump = notifier.goToRepliedMessage(
      messageId: _snowflakeForIndex(340),
      channelId: _channelId,
    );
    await _flushAsync();

    adapter
      ..holdDelete = true
      ..holdEdit = true;
    final Future<void> opA = notifier.deleteMessageAttachment(
      messageId: editedId,
      attachmentId: _kAttachmentId2,
    );
    final Future<void> opB = notifier.editAttachmentAltText(
      messageId: editedId,
      attachmentId: _kAttachmentId,
      description: 'alt for one',
    );
    await _flushAsync();

    // Issue order, the only order the queue allows. The edit is not even on
    // the wire yet, so releasing it first would release nothing.
    adapter.releaseDelete();
    await opA;
    await _flushAsync();
    adapter.releaseEdit();
    await opB;
    await _flushAsync();

    adapter.releaseAroundFetch();
    await jump;
    await _flushAsync();

    final Message committed = container
        .read(chatViewModelProvider)
        .messages
        .firstWhere((Message m) => m.id == editedId);
    expect(
      committed.attachments.map((Attachment a) => a.id),
      <String>[_kAttachmentId],
      reason:
          'the removal must survive the other operation on the same '
          'message',
    );
    expect(
      committed.attachments.single.description,
      'alt for one',
      reason: 'and so must the alt text',
    );
    await _flushAsync();
    expect(
      notifier.pendingLocalMutationCount,
      0,
      reason: 'both operations retire once no older page operation is left',
    );
  });

  test('m11: pagination is inside the protocol', () async {
    // loadMore is a page-producing fetch. Unregistered, it is invisible to
    // retirement, so an acknowledged tombstone is dropped while its page is
    // still in flight, and the page then reinstates the message. Registering
    // the fetch is what makes the overlay reachable at all.
    final _GatedDatabase database = await seedChannel();
    final adapter = _MessageApiAdapter(messages: _channelMessages(400));
    final container = _container(database, adapter);
    addTearDown(() {
      adapter.releaseOlderFetch();
      container.dispose();
    });

    final notifier = container.read(chatViewModelProvider.notifier);
    await notifier.switchChannel(_channelId);
    await _flushAsync();

    // In the older page loadMore is about to fetch, not in the window.
    final String deletedId = _snowflakeForIndex(340);
    expect(
      container.read(chatViewModelProvider).messages.map((Message m) => m.id),
      isNot(contains(deletedId)),
    );

    adapter.holdOlderFetch = true;
    final Future<void> older = notifier.loadMore();
    await _flushAsync();

    // Acknowledged while that page is still in flight.
    await notifier.deleteMessage(deletedId);
    await _flushAsync();

    expect(
      notifier.pendingLocalMutationCount,
      1,
      reason:
          'an in-flight pagination fetch older than the ack must keep the '
          'tombstone alive',
    );

    adapter.releaseOlderFetch();
    await older;
    await _flushAsync();

    expect(
      container.read(chatViewModelProvider).messages.map((Message m) => m.id),
      isNot(contains(deletedId)),
      reason:
          'a paginated page fetched before the delete must not resurrect '
          'the row',
    );
    expect(
      notifier.pendingLocalMutationCount,
      0,
      reason: 'and it retires once that fetch closes',
    );
  });

  test('m11b: the unread-boundary fetch is inside the protocol', () async {
    // Same two holes as pagination, on a fetch that lives outside
    // loadMore/loadNewer entirely.
    final _GatedDatabase database = await seedChannel();
    final adapter = _MessageApiAdapter(messages: _channelMessages(400));
    final container = _container(database, adapter);
    addTearDown(() {
      adapter.releaseAfterFetch();
      container.dispose();
    });

    // An ack strictly inside the loaded window is what triggers the boundary
    // load; the row it will resurrect sits after that ack.
    await database.readStateDao.upsertReadState(
      db.ReadStatesCompanion.insert(
        channelId: _channelId,
        lastMessageId: Value(_snowflakeForIndex(360)),
      ),
    );
    final String deletedId = _snowflakeForIndex(370);

    final notifier = container.read(chatViewModelProvider.notifier);
    adapter.holdAfterFetch = true;
    await notifier.switchChannel(_channelId);
    await _flushAsync();

    _activateViewport(container);
    final Future<void> ack = notifier.ackCurrentChannel();
    await _flushAsync();
    expect(
      adapter.afterFetchCalls,
      greaterThan(0),
      reason: 'the boundary fetch must actually be in flight',
    );

    await notifier.deleteMessage(deletedId);
    await _flushAsync();
    expect(
      notifier.pendingLocalMutationCount,
      1,
      reason:
          'an in-flight boundary fetch older than the ack must keep the '
          'tombstone alive',
    );

    adapter.releaseAfterFetch();
    await ack;
    await _flushAsync();

    expect(
      container.read(chatViewModelProvider).messages.map((Message m) => m.id),
      isNot(contains(deletedId)),
      reason: 'the boundary rows must not resurrect a deleted message',
    );
    expect(notifier.pendingLocalMutationCount, 0);
  });

  test('m11c: a boundary fetch discards when the window is replaced under '
      'it', () async {
    // Every post-await guard here used to be a channel check. A jump replacing
    // the window in the SAME channel leaves the fetched rows describing a
    // window that no longer exists.
    final _GatedDatabase database = await seedChannel();
    final adapter = _MessageApiAdapter(messages: _channelMessages(400));
    final container = _container(database, adapter);
    addTearDown(() {
      adapter.releaseAfterFetch();
      container.dispose();
    });

    await database.readStateDao.upsertReadState(
      db.ReadStatesCompanion.insert(
        channelId: _channelId,
        lastMessageId: Value(_snowflakeForIndex(360)),
      ),
    );

    final notifier = container.read(chatViewModelProvider.notifier);
    adapter.holdAfterFetch = true;
    await notifier.switchChannel(_channelId);
    await _flushAsync();

    _activateViewport(container);
    final Future<void> ack = notifier.ackCurrentChannel();
    await _flushAsync();
    expect(adapter.afterFetchCalls, greaterThan(0));

    // Same channel, wholesale replacement: the around window lands far from
    // the tail the boundary rows belong to.
    await notifier.goToRepliedMessage(
      messageId: _snowflakeForIndex(100),
      channelId: _channelId,
    );
    await _flushAsync();
    final List<String> replaced = container
        .read(chatViewModelProvider)
        .messages
        .map((Message m) => m.id)
        .toList();
    expect(replaced, isNot(contains(_snowflakeForIndex(370))));

    adapter.releaseAfterFetch();
    await ack;
    await _flushAsync();

    expect(
      container.read(chatViewModelProvider).messages.map((Message m) => m.id),
      replaced,
      reason:
          'rows qualified against the old window must not be merged into '
          'the new one',
    );
    expect(
      notifier.loadedUnreadBoundaryKeyCount,
      0,
      reason: 'a discarded attempt must not suppress the boundary forever',
    );
  });

  test('m11d: a boundary fetch discards when a targeted switch blanks the '
      'window', () async {
    // The dimension neither window counter can see: switchChannel's targeted
    // branch blanks the window synchronously in the SAME channel. It is a
    // direct write, not a swap commit, and it bumps only the switch
    // generation, so channelId, _windowGeneration and _windowWrites all still
    // match when the boundary fetch returns.
    final _GatedDatabase database = await seedChannel();
    final adapter = _MessageApiAdapter(messages: _channelMessages(400));
    final container = _container(database, adapter);
    addTearDown(() {
      adapter
        ..releaseAfterFetch()
        ..releaseAroundFetch();
      container.dispose();
    });

    await database.readStateDao.upsertReadState(
      db.ReadStatesCompanion.insert(
        channelId: _channelId,
        lastMessageId: Value(_snowflakeForIndex(360)),
      ),
    );

    final notifier = container.read(chatViewModelProvider.notifier);
    adapter.holdAfterFetch = true;
    await notifier.switchChannel(_channelId);
    await _flushAsync();

    _activateViewport(container);
    final Future<void> ack = notifier.ackCurrentChannel();
    await _flushAsync();
    expect(adapter.afterFetchCalls, greaterThan(0));

    // Same channel, targeted: the window blanks on the spot and its load is
    // held, so the boundary rows come back to an EMPTY window.
    adapter.holdAroundFetch = true;
    final Future<void> targeted = notifier.switchChannel(
      _channelId,
      targetMessageId: _snowflakeForIndex(100),
    );
    await _flushAsync();
    expect(
      container.read(chatViewModelProvider).messages,
      isEmpty,
      reason: 'the targeted switch blanked the window',
    );

    adapter.releaseAfterFetch();
    await ack;
    await _flushAsync();

    expect(
      container.read(chatViewModelProvider).messages,
      isEmpty,
      reason: 'boundary rows must not become the entire window',
    );
    expect(
      notifier.loadedUnreadBoundaryKeyCount,
      0,
      reason: 'a discarded attempt must not suppress the boundary forever',
    );

    adapter.releaseAroundFetch();
    await targeted;
    await _flushAsync();
  });

  test("m12: a superseded pagination does not clear its successor's busy "
      'flag', () async {
    // Inverted sibling of the isLoading wedge: instead of holding its own flag
    // down forever, a stale request clears somebody else's. B is then running
    // with its busy flag false, so a third load can start on top of it, which
    // is exactly the overlap the flag exists to prevent.
    final _GatedDatabase database = await seedChannel();
    final adapter = _MessageApiAdapter(messages: _channelMessages(400));
    final container = _container(database, adapter);
    addTearDown(() {
      adapter.releaseOlderFetch();
      container.dispose();
    });

    final notifier = container.read(chatViewModelProvider.notifier);
    await notifier.switchChannel(_channelId);
    await _flushAsync();

    adapter.holdOlderFetch = true;
    final Future<void> a = notifier.loadMore();
    await _flushAsync();
    expect(container.read(chatViewModelProvider).isLoadingMore, isTrue);

    // Same channel, no load: keeps the window and RESETS the busy flag.
    await notifier.switchChannel(_channelId, loadMessages: false);
    await _flushAsync();
    expect(
      container.read(chatViewModelProvider).isLoadingMore,
      isFalse,
      reason: 'the switch reset the flag, so a new pagination may start',
    );

    // Move the window anchor so B issues a genuinely distinct request rather
    // than being deduplicated onto A's in-flight future. Dropping the row from
    // the store as well keeps B off the cache path, which would otherwise
    // satisfy it synchronously and defeat the interleave.
    final String oldest = container
        .read(chatViewModelProvider)
        .messages
        .first
        .id;
    await database.messageDao.deleteMessages(<String>[oldest]);
    _emitDeleted(container, id: oldest);
    await _flushAsync();

    final Future<void> b = notifier.loadMore();
    await _flushAsync();
    expect(
      container.read(chatViewModelProvider).isLoadingMore,
      isTrue,
      reason: 'B owns the flag now',
    );

    // A returns to a window whose anchor moved: superseded.
    adapter.releaseFirstOlderFetch();
    await a;
    await _flushAsync();
    expect(
      container.read(chatViewModelProvider).isLoadingMore,
      isTrue,
      reason: "a superseded request must not clear its successor's flag",
    );

    adapter.releaseOlderFetch();
    await b;
    await _flushAsync();
    expect(
      container.read(chatViewModelProvider).isLoadingMore,
      isFalse,
      reason: 'the owner clears it normally',
    );
  });

  test('m12b: two paginations in flight both land, coherently', () async {
    // Adjudicates whether a pagination completing while another is in flight
    // should install or go inert. It installs: both helpers recompute from a
    // FRESH window and only the anchor proves adjacency, so the two pages are
    // independent and both are genuinely valid.
    final _GatedDatabase database = await seedChannel(
      lastMessageId: _snowflakeForIndex(399),
    );
    final adapter = _MessageApiAdapter(messages: _channelMessages(400));
    final container = _container(database, adapter);
    addTearDown(() {
      adapter
        ..releaseOlderFetch()
        ..releaseAfterFetch();
      container.dispose();
    });

    final notifier = container.read(chatViewModelProvider.notifier);
    // A small detached window: both sides open, and far enough under the trim
    // cap that neither install can drop the other's anchor.
    await notifier.switchChannel(
      _channelId,
      targetMessageId: _snowflakeForIndex(200),
    );
    await _flushAsync();
    final ChatViewState opened = container.read(chatViewModelProvider);
    expect(opened.hasMoreMessages, isTrue);
    expect(opened.hasMoreNewerMessages, isTrue);
    final String firstBefore = opened.messages.first.id;
    final String lastBefore = opened.messages.last.id;

    adapter
      ..holdOlderFetch = true
      ..holdAfterFetch = true;
    final Future<void> older = notifier.loadMore();
    final Future<void> newer = notifier.loadNewer();
    await _flushAsync();
    expect(container.read(chatViewModelProvider).isLoadingMore, isTrue);
    expect(container.read(chatViewModelProvider).isLoadingNewer, isTrue);

    // The older page lands while the newer one is still out.
    adapter.releaseOlderFetch();
    await older;
    await _flushAsync();
    final ChatViewState mid = container.read(chatViewModelProvider);
    expect(
      compareSnowflakeIds(mid.messages.first.id, firstBefore) < 0,
      isTrue,
      reason: 'the older page installed rather than being discarded',
    );
    expect(mid.messages.last.id, lastBefore);
    expect(
      mid.isLoadingNewer,
      isTrue,
      reason: "the other pagination's flag is untouched",
    );
    expect(mid.isLoadingMore, isFalse);

    adapter.releaseAfterFetch();
    await newer;
    await _flushAsync();

    final ChatViewState end = container.read(chatViewModelProvider);
    final List<String> ids = end.messages.map((Message m) => m.id).toList();
    expect(
      compareSnowflakeIds(ids.first, firstBefore) < 0,
      isTrue,
      reason: 'the older page survived the newer install',
    );
    expect(
      compareSnowflakeIds(ids.last, lastBefore) > 0,
      isTrue,
      reason: 'the newer page installed too',
    );
    expect(ids.toSet().length, ids.length, reason: 'no duplicated rows');
    for (var i = 1; i < ids.length; i++) {
      expect(
        compareSnowflakeIds(ids[i], ids[i - 1]) > 0,
        isTrue,
        reason: 'the merged window is strictly ordered',
      );
    }
    expect(end.isLoadingMore, isFalse);
    expect(end.isLoadingNewer, isFalse);
  });

  test('m12c: a pagination whose flag was reset with no successor still '
      'installs', () async {
    // The reachable-but-unobserved case behind the install-vs-inert
    // adjudication: a same-channel no-load switch resets the busy flag while
    // KEEPING the window, and no second pagination ever starts. A returns
    // anchor-intact and its page is valid, so it must land. Without this pin,
    // a plausible hardening that skips the install when the flag is down would
    // silently discard pages the user scrolled for, with the suite green.
    final _GatedDatabase database = await seedChannel();
    final adapter = _MessageApiAdapter(messages: _channelMessages(400));
    final container = _container(database, adapter);
    addTearDown(() {
      adapter.releaseOlderFetch();
      container.dispose();
    });

    final notifier = container.read(chatViewModelProvider.notifier);
    await notifier.switchChannel(_channelId);
    await _flushAsync();
    final String firstBefore = container
        .read(chatViewModelProvider)
        .messages
        .first
        .id;

    adapter.holdOlderFetch = true;
    final Future<void> older = notifier.loadMore();
    await _flushAsync();
    expect(container.read(chatViewModelProvider).isLoadingMore, isTrue);

    // Resets the flag, keeps the window, starts nothing.
    await notifier.switchChannel(_channelId, loadMessages: false);
    await _flushAsync();
    expect(container.read(chatViewModelProvider).isLoadingMore, isFalse);
    expect(
      container.read(chatViewModelProvider).messages.first.id,
      firstBefore,
      reason: 'the no-load switch kept the window, so the anchor still holds',
    );

    adapter
      ..holdOlderFetch = false
      ..releaseOlderFetch();
    await older;
    await _flushAsync();

    final ChatViewState afterA = container.read(chatViewModelProvider);
    expect(
      compareSnowflakeIds(afterA.messages.first.id, firstBefore) < 0,
      isTrue,
      reason: 'the page A fetched must install; nothing superseded it',
    );
    expect(afterA.isLoadingMore, isFalse);
    expect(afterA.isLoadingNewer, isFalse);
    final List<String> ids = afterA.messages.map((Message m) => m.id).toList();
    expect(ids.toSet().length, ids.length);

    // _contiguity.extendOlder is not observable in this shape: the store holds
    // nothing older than the page A just installed, so the next load goes to
    // the network whether or not contiguity was extended. The install, the
    // flags and the ordering above are what the inert policies change.
  });

  test("m14: a superseded jump to latest does not clear its successor's sync "
      'flag', () async {
    // Flag-ownership twin of m12, one flag over and one operation over. A jump
    // to latest is preempted by a same-channel around jump, which sets
    // isSyncingMessages for ITSELF. A then resumes, finds itself superseded and
    // runs its finally while B is still fetching: a clear gated only on the
    // channel id matches, so it drops B's flag and every dedup guard and busy
    // gate reads the channel as idle for the rest of B's run.
    final _GatedDatabase database = await seedChannel();
    final adapter = _MessageApiAdapter(messages: _channelMessages(400));
    final container = _container(database, adapter);
    addTearDown(() {
      adapter
        ..releaseLatestFetch()
        ..releaseAroundFetch();
      container.dispose();
    });

    final notifier = container.read(chatViewModelProvider.notifier);
    await detachWindow(notifier, container);

    adapter.holdLatestFetch = true;
    final Future<bool> a = notifier.jumpToLatestMessages();
    await _flushAsync();
    expect(
      container.read(chatViewModelProvider).isSyncingMessages,
      isTrue,
      reason: 'A owns the flag while its page is out',
    );

    // B is same-channel, so no channel check can tell the two apart. Target the
    // oldest row the window does NOT hold, so B has to fetch instead of
    // scrolling to something already loaded, and its own arm is what
    // supersedes A.
    final Set<String> loaded = container
        .read(chatViewModelProvider)
        .messages
        .map((Message m) => m.id)
        .toSet();
    final String targetB = List<String>.generate(
      400,
      _snowflakeForIndex,
    ).firstWhere((String id) => !loaded.contains(id));
    adapter.holdAroundFetch = true;
    final Future<void> b = notifier.goToRepliedMessage(
      channelId: _channelId,
      messageId: targetB,
    );
    await _flushAsync();
    expect(
      container.read(chatViewModelProvider).isSyncingMessages,
      isTrue,
      reason: 'B set the flag for itself; it owns it now',
    );

    // A comes back to a window that moved under it and reaches its finally
    // while B is still parked in its fetch.
    adapter.releaseLatestFetch();
    expect(
      await a,
      isFalse,
      reason: 'a superseded jump must not report success',
    );
    await _flushAsync();
    expect(
      container.read(chatViewModelProvider).isSyncingMessages,
      isTrue,
      reason: "a superseded jump must not clear its successor's flag",
    );

    adapter.releaseAroundFetch();
    await b;
    await _flushAsync();
    final ChatViewState end = container.read(chatViewModelProvider);
    expect(
      end.messages.map((Message m) => m.id),
      contains(targetB),
      reason: 'the winning jump still lands normally',
    );
    expect(
      end.isSyncingMessages,
      isFalse,
      reason: 'the owner clears it on its own lifecycle',
    );
  });

  test('m14b: a superseded jump to latest still releases the jump '
      'mutex', () async {
    // The m12c lesson one flag over: the SAFE half of the ownership rule needs
    // pinning too. _jumpToLatestActive is a mutex, not a busy flag, and the
    // entry guard means no successor can ever own it, so a superseded jump must
    // ALWAYS clear it. Symmetry-gating it like the isSyncingMessages line below
    // it looks like the same hardening and instead wedges jump-to-latest shut
    // for the rest of the channel's life, with every other test still green.
    final _GatedDatabase database = await seedChannel();
    final adapter = _MessageApiAdapter(messages: _channelMessages(400));
    final container = _container(database, adapter);
    addTearDown(() {
      adapter
        ..releaseLatestFetch()
        ..releaseAroundFetch();
      container.dispose();
    });

    final notifier = container.read(chatViewModelProvider.notifier);
    await detachWindow(notifier, container);

    // Same interleave as m14: A is held, B supersedes it in the same channel.
    adapter.holdLatestFetch = true;
    final Future<bool> a = notifier.jumpToLatestMessages();
    await _flushAsync();
    final Set<String> loaded = container
        .read(chatViewModelProvider)
        .messages
        .map((Message m) => m.id)
        .toSet();
    final String targetB = List<String>.generate(
      400,
      _snowflakeForIndex,
    ).firstWhere((String id) => !loaded.contains(id));
    adapter.holdAroundFetch = true;
    final Future<void> b = notifier.goToRepliedMessage(
      channelId: _channelId,
      messageId: targetB,
    );
    await _flushAsync();

    adapter.releaseLatestFetch();
    expect(await a, isFalse, reason: 'A is superseded, as in m14');
    adapter.releaseAroundFetch();
    await b;
    await _flushAsync();

    // B installed an around window, so the tail is still off screen and a jump
    // is the only way back to it.
    final ChatViewState afterB = container.read(chatViewModelProvider);
    expect(
      afterB.hasMoreNewerMessages,
      isTrue,
      reason:
          'without a detached window the jump short-circuits and proves '
          'nothing about the mutex',
    );
    final String tailId = _snowflakeForIndex(399);
    expect(afterB.messages.map((Message m) => m.id), isNot(contains(tailId)));
    final int fetchesBefore = adapter.latestFetchCalls;
    final int scrollBefore = afterB.scrollToBottomSignal;

    final bool ok = await notifier.jumpToLatestMessages();
    await _flushAsync();
    expect(
      ok,
      isTrue,
      reason:
          'the mutex the superseded jump owned must have been released, or '
          'jump-to-latest is wedged shut for good',
    );
    expect(
      adapter.latestFetchCalls,
      fetchesBefore + 1,
      reason:
          'it took the normal path and fetched, rather than returning '
          'early off a stale mutex or a short-circuit',
    );
    final ChatViewState end = container.read(chatViewModelProvider);
    expect(
      end.messages.map((Message m) => m.id),
      contains(tailId),
      reason: 'the second jump landed on the live tail',
    );
    expect(end.hasMoreNewerMessages, isFalse);
    expect(end.scrollToBottomSignal, greaterThan(scrollBefore));
    expect(end.isSyncingMessages, isFalse);
  });

  test('m15: a superseded recovery reconcile neither clears the jump flag nor '
      'marks the channel reconciled', () async {
    // The reconcile is the repair path for a stale window after session
    // recovery, and it had both halves of the ownership bug at once. It must not
    // report success on a page it never installed, because the mark suppresses
    // the NEXT resync and the stale window then outlives the recovery it exists
    // to repair; and it must not clear the busy flag of the jump that
    // superseded it. _refreshMessagesFromNetwork returns NORMALLY when
    // superseded, so neither half can be read off control flow or a channel id.
    final _GatedDatabase database = await seedChannel();
    final adapter = _MessageApiAdapter(messages: _channelMessages(400));
    final container = _container(database, adapter);
    addTearDown(() {
      adapter
        ..releaseAroundFetch()
        ..releaseLatestFetch();
      container.dispose();
    });

    final notifier = container.read(chatViewModelProvider.notifier);
    // A detached window: the reconcile preserves it and fetches AROUND it, which
    // also keeps its gate independent of the jump's latest-page gate.
    await detachWindow(notifier, container);

    // A is the real recovery path: production bumps this on gateway
    // READY/RESUMED and the view model reconciles off the listener.
    adapter.holdAroundFetch = true;
    container.read(gatewaySessionRecoveryProvider.notifier).bump();
    await _flushAsync();
    expect(
      adapter.aroundFetchCalls,
      greaterThan(0),
      reason: 'the reconcile must actually be in flight, or this is vacuous',
    );
    expect(
      container.read(chatViewModelProvider).isSyncingMessages,
      isTrue,
      reason: 'the reconcile owns the flag while its pages are out',
    );

    // B supersedes A by bumping the window generation. It sets the flag for
    // itself, and it is already true, which is exactly why a channel check
    // cannot tell the two owners apart.
    adapter.holdLatestFetch = true;
    final Future<bool> b = notifier.jumpToLatestMessages();
    await _flushAsync();

    // A returns to a window that is no longer its own and installs nothing.
    adapter.releaseAroundFetch();
    await _flushAsync();
    expect(
      container.read(chatViewModelProvider).isSyncingMessages,
      isTrue,
      reason: "the superseded reconcile must not clear the jump's flag",
    );

    adapter.releaseLatestFetch();
    expect(await b, isTrue, reason: 'the jump still lands normally');
    await _flushAsync();
    final ChatViewState afterJump = container.read(chatViewModelProvider);
    expect(
      afterJump.isSyncingMessages,
      isFalse,
      reason: 'the owner clears it on its own lifecycle',
    );
    expect(
      afterJump.messages.map((Message m) => m.id),
      contains(_snowflakeForIndex(399)),
    );

    // The mark itself is private, but the machinery that reads it is not: a
    // same-channel switch resyncs only while the channel is NOT marked
    // reconciled for the current recovery generation. A mark from the
    // superseded reconcile silences that resync, and the stale window stays.
    final int aroundBefore = adapter.aroundFetchCalls;
    await notifier.switchChannel(_channelId);
    await _flushAsync();
    expect(
      adapter.aroundFetchCalls,
      greaterThan(aroundBefore),
      reason: 'nothing reconciled this channel, so the resync must still run',
    );
  });

  test('m15b: a superseded refresh does not write its failure over the '
      'successor', () async {
    // reloadCurrentChannel passes no shouldApplyResult, so this refresh's
    // shouldApply predicate is the window generation ALONE. A same-channel
    // no-load switch supersedes it by bumping the SWITCH generation while
    // keeping the window and writing its own flags, which that predicate cannot
    // see. The refresh then fails, and its cleanup raises a banner and clears
    // busy flags over state owned by an operation that never failed.
    final _GatedDatabase database = await seedChannel();
    final adapter = _MessageApiAdapter(messages: _channelMessages(400));
    final container = _container(database, adapter);
    addTearDown(() {
      adapter.releaseLatestFetch();
      container.dispose();
    });

    final notifier = container.read(chatViewModelProvider.notifier);
    await notifier.switchChannel(_channelId);
    await _flushAsync();
    final int loaded = container.read(chatViewModelProvider).messages.length;
    expect(loaded, greaterThan(0));

    adapter
      ..holdLatestFetch = true
      ..failLatestFetch = true;
    final Future<void> a = notifier.reloadCurrentChannel();
    await _flushAsync();
    expect(
      container.read(chatViewModelProvider).isLoading,
      isTrue,
      reason: 'A is in flight and owns the spinner',
    );

    await notifier.switchChannel(_channelId, loadMessages: false);
    await _flushAsync();
    final ChatViewState afterSwitch = container.read(chatViewModelProvider);
    expect(afterSwitch.isLoading, isFalse, reason: 'the switch owns the flags');
    expect(
      afterSwitch.messages.length,
      loaded,
      reason:
          'the no-load switch keeps the window, so the failure below has a '
          'cached window to lie about',
    );
    expect(afterSwitch.errorMessage, isNull);
    expect(afterSwitch.messageLoadFailed, isFalse);

    // A fails only now, long after it stopped owning any of this.
    adapter.releaseLatestFetch();
    await a;
    await _flushAsync();
    final ChatViewState end = container.read(chatViewModelProvider);
    expect(
      end.errorMessage,
      isNull,
      reason:
          'a superseded refresh must not raise a failure banner over the '
          'successor that replaced it',
    );
    expect(
      end.messageLoadFailed,
      isFalse,
      reason: 'the operation that owns this state did not fail',
    );
    expect(end.messages.length, loaded, reason: 'the window is untouched');
  });

  test('m15c: a superseded sibling refresh writes no failure over the refresh '
      'that replaced it', () async {
    // Refresh-vs-refresh supersession bumps NO generation. The second refresh's
    // arm silently replaces the first's token, and that IS the whole difference
    // between them, so no generation predicate can separate the two. A recovery
    // reconcile and a manual retry are two such refreshes on one channel, and
    // retry has no busy-entry guard by design, so the overlap is reachable
    // straight from the UI.
    final _GatedDatabase database = await seedChannel();
    final adapter = _MessageApiAdapter(messages: _channelMessages(400));
    final container = _container(database, adapter);
    addTearDown(() {
      adapter
        ..releaseAroundFetch()
        ..releaseLatestFetch();
      container.dispose();
    });

    final notifier = container.read(chatViewModelProvider.notifier);
    await notifier.switchChannel(_channelId);
    await _flushAsync();
    final int loaded = container.read(chatViewModelProvider).messages.length;
    expect(loaded, greaterThan(0));

    // A: the recovery reconcile, arming and then parked in its window-preserving
    // around fetch, rigged to fail when released.
    adapter
      ..holdAroundFetch = true
      ..failAroundFetch = true;
    container.read(gatewaySessionRecoveryProvider.notifier).bump();
    await _flushAsync();
    expect(
      adapter.aroundFetchCalls,
      greaterThan(0),
      reason: 'A must really be in flight, or this is vacuous',
    );
    expect(container.read(chatViewModelProvider).isSyncingMessages, isTrue);

    // B: a manual retry on the SAME channel. Re-arming is the only trace it
    // leaves of superseding A; it raises its own spinner.
    adapter.holdLatestFetch = true;
    final Future<void> b = notifier.retryLoadMessages();
    await _flushAsync();
    expect(
      container.read(chatViewModelProvider).isLoading,
      isTrue,
      reason: 'B owns the spinner now',
    );

    // A fails, after B has taken the arm.
    adapter.releaseAroundFetch();
    await _flushAsync();
    final ChatViewState afterA = container.read(chatViewModelProvider);
    expect(
      afterA.isLoading,
      isTrue,
      reason: "a superseded sibling must not clear B's spinner",
    );
    expect(
      afterA.errorMessage,
      isNull,
      reason: 'B has not failed, so no banner may be raised over it',
    );
    expect(afterA.messageLoadFailed, isFalse);

    // B finishes normally and owns every flag it raised.
    adapter.releaseLatestFetch();
    await b;
    await _flushAsync();
    final ChatViewState end = container.read(chatViewModelProvider);
    expect(end.isLoading, isFalse, reason: 'the owner clears its own spinner');
    expect(end.errorMessage, isNull);
    expect(end.messageLoadFailed, isFalse);
    // A retry installs a fresh latest page wholesale, so it is the tail that
    // proves the install, not the count: its page size is smaller than the one
    // the channel opened with.
    expect(end.messages, isNotEmpty);
    expect(
      end.messages.last.id,
      _snowflakeForIndex(399),
      reason: "B's own page installed",
    );
  });

  test('m13: a failed removal leaves the next operation on the confirmed '
      'baseline', () async {
    // The failure leg of the serialised queue. A is held and will fail; B is
    // issued behind it. When A fails there is no inverse to apply: the
    // optimistic row is re-derived as confirmed + whatever is still queued, so
    // A's attachment simply comes back. B then dispatches against the
    // ORIGINAL confirmed row, both attachments included, and lands.
    const int attachmentIndex = 352;
    final _GatedDatabase database = await seedChannel();
    final adapter = _MessageApiAdapter(
      messages: _channelMessages(
        400,
        attachmentAt: attachmentIndex,
        twoAttachments: true,
      ),
    );
    final container = _container(database, adapter);
    addTearDown(() {
      adapter.releaseDelete();
      container.dispose();
    });

    final notifier = container.read(chatViewModelProvider.notifier);
    await notifier.switchChannel(_channelId);
    await _flushAsync();

    final String messageId = _snowflakeForIndex(attachmentIndex);

    // A: remove the second attachment. Held, and it will fail.
    adapter
      ..holdDelete = true
      ..failDelete = true;
    final Future<void> opA = notifier.deleteMessageAttachment(
      messageId: messageId,
      attachmentId: _kAttachmentId2,
    );
    await _flushAsync();

    // B: alt text on the OTHER attachment of the same message. Queued behind
    // A, so it is not on the wire yet.
    final Future<void> opB = notifier.editAttachmentAltText(
      messageId: messageId,
      attachmentId: _kAttachmentId,
      description: 'B description',
    );
    await _flushAsync();
    expect(
      adapter.attachmentRequests,
      <String>['DELETE $_kAttachmentId2'],
      reason: 'B must wait for A to settle before it touches the wire',
    );

    // A now fails; B dispatches behind it.
    adapter.releaseDelete();
    await opA;
    await opB;
    await _flushAsync();
    expect(
      adapter.attachmentRequests.last,
      'PATCH $_kAttachmentId2,$_kAttachmentId=B description',
      reason:
          "a failed operation confirms nothing, so B's array is the ORIGINAL "
          'confirmed one',
    );

    final Message row = container
        .read(chatViewModelProvider)
        .messages
        .firstWhere((Message m) => m.id == messageId);
    expect(
      row.attachments.map((Attachment a) => a.id),
      containsAll(<String>[_kAttachmentId, _kAttachmentId2]),
      reason: 'the failed removal put its own attachment back',
    );
    expect(
      row.attachments
          .firstWhere((Attachment a) => a.id == _kAttachmentId)
          .description,
      'B description',
      reason: "a rollback must not revert another operation's confirmed work",
    );
  });

  test('m13c: attachment mutations are serialised and derive from the '
      'confirmed row', () async {
    // The transport pin. `deleteAttachment` is a targeted DELETE, but
    // `editMessageAttachments` PATCHes the WHOLE array. Run them at once and
    // the edit's array - built while the delete is still in flight - still
    // lists the deleted attachment, so the server RE-CREATES it after the
    // delete confirmed. No client-side rollback can undo that, so the client
    // must not create the race: one request per message at a time, each built
    // at dispatch time from the row the server last confirmed.
    const int attachmentIndex = 352;
    final _GatedDatabase database = await seedChannel();
    final adapter = _MessageApiAdapter(
      messages: _channelMessages(
        400,
        attachmentAt: attachmentIndex,
        twoAttachments: true,
      ),
    );
    final container = _container(database, adapter);
    addTearDown(() {
      adapter.releaseDelete();
      container.dispose();
    });

    final notifier = container.read(chatViewModelProvider.notifier);
    await notifier.switchChannel(_channelId);
    await _flushAsync();

    final String messageId = _snowflakeForIndex(attachmentIndex);

    adapter.holdDelete = true;
    final Future<void> opA = notifier.deleteMessageAttachment(
      messageId: messageId,
      attachmentId: _kAttachmentId2,
    );
    final Future<void> opB = notifier.editAttachmentAltText(
      messageId: messageId,
      attachmentId: _kAttachmentId,
      description: 'alt for one',
    );
    await _flushAsync();

    expect(
      adapter.attachmentRequests,
      <String>['DELETE $_kAttachmentId2'],
      reason:
          'the whole-array PATCH must not be on the wire beside the '
          'DELETE it would undo',
    );

    adapter.releaseDelete();
    await opA;
    await opB;
    await _flushAsync();

    expect(
      adapter.attachmentRequests,
      <String>['DELETE $_kAttachmentId2', 'PATCH $_kAttachmentId=alt for one'],
      reason:
          'the edit rewrites the whole array, so it must derive from the '
          'CONFIRMED post-delete row: listing the removed attachment '
          're-creates it server-side',
    );

    final Message row = container
        .read(chatViewModelProvider)
        .messages
        .firstWhere((Message m) => m.id == messageId);
    expect(
      row.attachments.map((Attachment a) => a.id),
      <String>[_kAttachmentId],
      reason: 'the canonical row the edit returned is the new baseline',
    );
    expect(row.attachments.single.description, 'alt for one');
    expect(
      notifier.pendingLocalMutationCount,
      0,
      reason: 'both operations retired',
    );
  });

  test('m13d: an attachment edit transmits no content', () async {
    // Field ownership, one layer down, on the wire. The endpoint accepts
    // `content` on the same PATCH that rewrites the attachment array, so an
    // alt-text op that fills the field in ships a value it merely READ. The
    // per-message queue serialises OUR requests; it cannot serialise against
    // another client, so a remote edit landing while our request is in flight
    // is overwritten by the text we sent. The only defence is to send nothing
    // this operation owns, and the SDK omits the part when the argument is
    // null.
    const int attachmentIndex = 352;
    final _GatedDatabase database = await seedChannel();
    final adapter = _MessageApiAdapter(
      messages: _channelMessages(400, attachmentAt: attachmentIndex),
    );
    final container = _container(database, adapter);
    addTearDown(() {
      adapter.releaseEdit();
      container.dispose();
    });

    final notifier = container.read(chatViewModelProvider.notifier);
    await notifier.switchChannel(_channelId);
    await _flushAsync();

    final String messageId = _snowflakeForIndex(attachmentIndex);

    adapter.holdEdit = true;
    final Future<void> edit = notifier.editAttachmentAltText(
      messageId: messageId,
      attachmentId: _kAttachmentId,
      description: 'alt for one',
    );
    await _flushAsync();

    // Another client edits the text while our request is in flight: server
    // side, and on the bus, which is how it reaches this window.
    adapter.serverContent[messageId] = 'edited remotely';
    _emitUpdated(container, id: messageId, content: 'edited remotely');
    await _flushAsync();

    adapter.releaseEdit();
    await edit;
    await _flushAsync();

    expect(
      adapter.patchContents,
      <String?>[null],
      reason:
          'the attachment PATCH must omit the content part entirely, not '
          'send a value it only read',
    );
    expect(
      adapter.serverContent[messageId],
      'edited remotely',
      reason: 'an operation must not overwrite a field it does not own',
    );
    final db.Message? row = await database.messageDao.getMessage(messageId);
    expect(
      row?.content,
      'edited remotely',
      reason:
          'the canonical response is upserted, so a stale content in it '
          'poisons the local cache too',
    );
    expect(
      _contentOf(container, messageId),
      'edited remotely',
      reason: 'and the window keeps the remote edit',
    );
    expect(
      container
          .read(chatViewModelProvider)
          .messages
          .firstWhere((Message m) => m.id == messageId)
          .attachments
          .single
          .description,
      'alt for one',
      reason: 'while the operation it DOES own still lands',
    );
  });

  test('m10d: a page fetched after the acknowledgement wins', () async {
    // The other direction, and it is load-bearing: once the server has
    // confirmed the mutation, a fetch begun later is guaranteed to reflect it.
    // Overlaying that page would mask server truth forever, so a
    // delete-then-recreate could never come back.
    final _GatedDatabase database = await seedChannel();
    final adapter = _MessageApiAdapter(messages: _channelMessages(400));
    final container = _container(database, adapter);
    addTearDown(() {
      adapter.releaseAroundFetch();
      container.dispose();
    });

    final notifier = container.read(chatViewModelProvider.notifier);
    await detachWindow(notifier, container);

    final String recreatedId = _snowflakeForIndex(399);

    // An older page operation, held open for the whole test, so the log cannot
    // retire the entry before the assertion and the ordinal comparison is what
    // is actually under test.
    adapter.holdAroundFetch = true;
    final Future<void> holder = notifier.goToRepliedMessage(
      messageId: _snowflakeForIndex(120),
      channelId: _channelId,
    );
    await _flushAsync();

    await notifier.deleteMessage(recreatedId);
    await _flushAsync();

    // A fetch that BEGINS after the acknowledgement. Its page is server truth.
    adapter.holdAroundFetch = false;
    await notifier.goToRepliedMessage(
      messageId: _snowflakeForIndex(390),
      channelId: _channelId,
    );
    await _flushAsync();

    expect(
      container.read(chatViewModelProvider).messages.map((Message m) => m.id),
      contains(recreatedId),
      reason: 'a page fetched after the ack must not be overlaid',
    );

    adapter.releaseAroundFetch();
    await holder;
    await _flushAsync();
    expect(
      notifier.pendingLocalMutationCount,
      0,
      reason: 'the log must retire once no older page operation is left',
    );
  });

  test('m10c: a commit does not revert an edit made while it waited', () async {
    // An optimistic edit is a REPLACEMENT, and mergeMessagesSorted gives the
    // fetched page precedence over the local row, so a fresh read alone still
    // loses it. The overlay re-applies the local revision after the merge.
    const int attachmentIndex = 352;
    final _GatedDatabase database = await seedChannel(
      lastMessageId: _snowflakeForIndex(399),
    );
    final adapter = _MessageApiAdapter(
      messages: _channelMessages(400, attachmentAt: attachmentIndex),
    );
    final container = _container(database, adapter);
    addTearDown(container.dispose);

    final notifier = container.read(chatViewModelProvider.notifier);
    await notifier.switchChannel(_channelId);
    await _flushAsync();

    final String editedId = _snowflakeForIndex(attachmentIndex);
    expect(
      container
          .read(chatViewModelProvider)
          .messages
          .any((Message m) => m.id == editedId),
      isTrue,
      reason: 'the attachment message must start in the window',
    );

    final String parked = container
        .read(chatViewModelProvider)
        .messages
        .last
        .id;
    gate.hold(parked, content: 'reacted');
    _emitReactions(container, id: parked);
    await _flushAsync();

    // An around page that OVERLAPS the current window, so the page carries its
    // own pre-edit copy of the edited message.
    final Future<void> jump = notifier.goToRepliedMessage(
      messageId: _snowflakeForIndex(340),
      channelId: _channelId,
    );
    await _flushAsync();

    adapter.holdEdit = true;
    final Future<void> edit = notifier.editAttachmentAltText(
      messageId: editedId,
      attachmentId: _kAttachmentId,
      description: 'a local description',
    );
    await _flushAsync();

    gate.releaseAll();
    await jump;
    await _flushAsync();

    final Message committed = container
        .read(chatViewModelProvider)
        .messages
        .firstWhere((Message m) => m.id == editedId);
    expect(
      committed.attachments.single.description,
      'a local description',
      reason: "the page's pre-edit copy must not overwrite the local revision",
    );

    // Cleanup: once the edit settles the overlay entry must go, or the local
    // revision is pinned over every future page forever. A fresh page install
    // must show server truth again.
    adapter.releaseEdit();
    await edit;
    await _flushAsync();
    expect(await notifier.jumpToLatestMessages(), isTrue);
    await _flushAsync();
    final Message reloaded = container
        .read(chatViewModelProvider)
        .messages
        .firstWhere((Message m) => m.id == editedId);
    expect(
      reloaded.attachments.single.description,
      isNull,
      reason: 'a settled edit must not pin its revision over server truth',
    );
  });
}

ProviderContainer _container(
  db.FluxerDatabase database,
  _MessageApiAdapter adapter,
) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.fluxer.app/v1'))
    ..httpClientAdapter = adapter;
  final client = FluxerClient(dio, baseUrl: 'https://api.fluxer.app/v1');
  return ProviderContainer(
    overrides: [
      fluxerDatabaseProvider.overrideWithValue(database),
      appUiForegroundProvider.overrideWithValue(true),
      fluxerDioProvider.overrideWithValue(dio),
      fluxerClientProvider.overrideWithValue(client),
      currentUserIdProvider.overrideWithValue('me'),
      ackBatcherProvider.overrideWith((ref) {
        final batcher = AckBatcher(client: client, batchDelay: Duration.zero);
        ref.onDispose(() {
          unawaited(batcher.dispose());
        });
        return batcher;
      }),
      guildMemberHydrationServiceProvider.overrideWithValue(
        NoopGuildMemberHydrationService(database: database),
      ),
    ],
  );
}

void _activateViewport(ProviderContainer container) {
  container.read(chatReadViewportProvider.notifier)
    ..setViewportActive(channelId: _channelId, isActive: true)
    ..updateViewport(
      channelId: _channelId,
      nearLoadedTail: true,
      distanceFromBottom: 0,
      viewportHeight: 600,
    );
}

Future<void> _flushAsync() async {
  for (var i = 0; i < 8; i++) {
    await pumpEventQueue();
  }
  SchedulerBinding.instance.handleBeginFrame(Duration.zero);
  SchedulerBinding.instance.handleDrawFrame();
  for (var i = 0; i < 8; i++) {
    await pumpEventQueue();
  }
}

/// A single held `getMessage`.
class _GatedRead {
  _GatedRead(this.messageId);

  final String messageId;
  final Completer<void> completer = Completer<void>();
}

/// Parks `getMessage` for chosen message ids, and rewrites the content of the
/// row those reads return so a reducer that answers from the database is
/// distinguishable from one that answers from an event payload.
///
/// Releasing stops the parking but keeps the rewrite, so a reducer that has to
/// recompute after a swap does not deadlock on a gate it already passed.
class _MessageDaoGate {
  final Set<String> _parked = <String>{};
  final Map<String, String> _content = <String, String>{};
  final List<_GatedRead> _reads = <_GatedRead>[];

  void hold(String messageId, {required String content}) {
    _parked.add(messageId);
    _content[messageId] = content;
  }

  int get outstanding =>
      _reads.where((_GatedRead r) => !r.completer.isCompleted).length;

  _GatedRead? register(String messageId) {
    if (!_parked.contains(messageId)) {
      return null;
    }
    final _GatedRead read = _GatedRead(messageId);
    _reads.add(read);
    return read;
  }

  String? contentFor(String messageId) => _content[messageId];

  void releaseAll() {
    _parked.clear();
    for (final _GatedRead read in _reads) {
      if (!read.completer.isCompleted) {
        read.completer.complete();
      }
    }
  }
}

class _GatedMessageDao extends MessageDao {
  _GatedMessageDao(super.attachedDatabase, this._gate);

  final _MessageDaoGate _gate;

  @override
  Future<db.Message?> getMessage(String id) async {
    final _GatedRead? read = _gate.register(id);
    if (read != null) {
      await read.completer.future;
    }
    final db.Message? row = await super.getMessage(id);
    final String? content = _gate.contentFor(id);
    if (row == null || content == null) {
      return row;
    }
    return row.copyWith(content: content);
  }
}

class _GatedDatabase extends db.FluxerDatabase {
  _GatedDatabase(super.e, this._gate) : super.forTesting();

  final _MessageDaoGate _gate;

  late final MessageDao _gatedMessageDao = _GatedMessageDao(this, _gate);

  @override
  MessageDao get messageDao => _gatedMessageDao;
}

/// Models the message endpoint closely enough for window work: `around` on an
/// unknown id still returns the window it would have sorted into, and the
/// latest page can be held open so events land mid-swap.
class _MessageApiAdapter implements HttpClientAdapter {
  _MessageApiAdapter({required this.messages, this.sentMessageId = ''});

  final List<Map<String, Object?>> messages;

  /// Id the endpoint hands back for a POSTed message.
  final String sentMessageId;

  bool holdLatestFetch = false;

  /// Latest-page requests the client actually put on the wire. A jump that
  /// returns early off a stale mutex never reaches the endpoint at all.
  int latestFetchCalls = 0;

  /// Makes the held latest page fail once released, so the swap that armed on
  /// it reaches its finally without ever committing.
  bool failLatestFetch = false;

  Completer<void>? _latestCompleter;

  /// Keeps a POSTed message in flight so its optimistic row stays local-only.
  bool holdSend = false;
  Completer<void>? _sendCompleter;

  /// Keeps a DELETE in flight so its pending-mutation entry stays live.
  bool holdDelete = false;

  /// Makes the held DELETE fail once released, to drive the rollback path.
  bool failDelete = false;
  Completer<void>? _deleteCompleter;

  /// The `content` part of each attachment PATCH, `null` when the request
  /// omitted the field entirely. An operation that does not own the text must
  /// never transmit it.
  final List<String?> patchContents = <String?>[];

  /// The server's own content per message. A PATCH that carries `content`
  /// overwrites it, exactly as the endpoint does; one that omits the part
  /// leaves it alone.
  final Map<String, String> serverContent = <String, String>{};

  String _contentFor(String messageId) =>
      serverContent.putIfAbsent(messageId, () {
        final Map<String, Object?> row = messages.firstWhere(
          (Map<String, Object?> m) => m['id'] == messageId,
          orElse: () => const <String, Object?>{},
        );
        return row['content'] as String? ?? 'message $messageId';
      });

  /// Every attachment request the client actually put on the wire, in order.
  /// `DELETE <attachmentId>` or `PATCH <id>=<description>,...`.
  final List<String> attachmentRequests = <String>[];

  /// The server's own attachment array per message, seeded from the seeded
  /// message and mutated by DELETE and PATCH. A PATCH echoes it back, which is
  /// what the real endpoint does: it rewrites the WHOLE array and returns the
  /// canonical row.
  final Map<String, List<Map<String, Object?>>> _serverAttachments =
      <String, List<Map<String, Object?>>>{};

  List<Map<String, Object?>> _attachmentsFor(String messageId) =>
      _serverAttachments.putIfAbsent(messageId, () {
        final Map<String, Object?> row = messages.firstWhere(
          (Map<String, Object?> m) => m['id'] == messageId,
          orElse: () => const <String, Object?>{},
        );
        return <Map<String, Object?>>[
          for (final Object? a
              in row['attachments'] as List<Object?>? ?? const <Object?>[])
            Map<String, Object?>.from(a! as Map<String, Object?>),
        ];
      });

  /// Keeps an attachment edit in flight for the same reason.
  bool holdEdit = false;

  /// Makes the attachment edit fail once released, to drive the rollback path.
  bool failEdit = false;
  Completer<void>? _editCompleter;

  /// Keeps an `after` page in flight. This is the unread-boundary fetch: the
  /// repository routes it through the network page loader, not the DAO.
  bool holdAfterFetch = false;
  int afterFetchCalls = 0;
  Completer<void>? _afterCompleter;

  /// Keeps `before` (pagination) pages in flight, one completer per call, so
  /// two overlapping paginations can be released independently.
  bool holdOlderFetch = false;
  int olderFetchCalls = 0;
  final List<Completer<void>> _olderCompleters = <Completer<void>>[];

  /// Keeps an `around` page in flight, so its fetch ordinal stays outstanding.
  bool holdAroundFetch = false;

  /// Makes the held `around` page fail once released, which is how a refresh
  /// that has already been superseded reaches its failure cleanup.
  bool failAroundFetch = false;

  /// `around` requests on the wire. The window-preserving reconcile fetches
  /// around its window, so a resync the skip machinery silenced is visible as
  /// this count staying flat.
  int aroundFetchCalls = 0;
  Completer<void>? _aroundCompleter;

  void releaseLatestFetch() {
    holdLatestFetch = false;
    final completer = _latestCompleter;
    _latestCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  void releaseAfterFetch() {
    holdAfterFetch = false;
    final completer = _afterCompleter;
    _afterCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  void releaseOlderFetch() {
    holdOlderFetch = false;
    for (final Completer<void> completer in _olderCompleters) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
    _olderCompleters.clear();
  }

  /// Releases only the EARLIEST outstanding pagination fetch.
  void releaseFirstOlderFetch() {
    for (final Completer<void> completer in _olderCompleters) {
      if (!completer.isCompleted) {
        completer.complete();
        return;
      }
    }
  }

  void releaseAroundFetch() {
    holdAroundFetch = false;
    final completer = _aroundCompleter;
    _aroundCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  void releaseEdit() {
    holdEdit = false;
    final completer = _editCompleter;
    _editCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  void releaseSend() {
    holdSend = false;
    final completer = _sendCompleter;
    _sendCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  void releaseDelete() {
    holdDelete = false;
    final completer = _deleteCompleter;
    _deleteCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (RegExp(
      r'/channels/[^/]+/messages/[^/]+/ack$',
    ).hasMatch(options.uri.path)) {
      return ResponseBody.fromString('{}', 200, headers: _jsonHeaders);
    }
    final match = RegExp(
      r'/channels/([^/]+)/messages$',
    ).firstMatch(options.uri.path);
    if (options.method == 'PATCH') {
      final RegExpMatch? edited = RegExp(
        r'/channels/[^/]+/messages/([^/]+)$',
      ).firstMatch(options.uri.path);
      final String? rawBody = await _readRequestBody(
        requestStream,
        options.data,
      );
      final List<Object?> sent = _multipartAttachments(rawBody);
      final String? sentContent = _multipartField(rawBody, 'content');
      if (edited != null) {
        patchContents.add(sentContent);
        attachmentRequests.add(
          'PATCH ${sent.map((Object? e) {
            final Map<String, Object?> u = e! as Map<String, Object?>;
            return u.containsKey('description') ? '${u['id']}=${u['description']}' : '${u['id']}';
          }).join(',')}',
        );
      }
      if (holdEdit) {
        _editCompleter ??= Completer<void>();
        await _editCompleter!.future;
      }
      if (failEdit) {
        return ResponseBody.fromString('boom', 500);
      }
      if (edited != null) {
        // The endpoint rewrites the whole array: keep exactly the ids sent, in
        // the order sent, applying any description the request carries.
        final List<Map<String, Object?>> current = _attachmentsFor(
          edited.group(1)!,
        );
        final List<Map<String, Object?>> next = <Map<String, Object?>>[
          for (final Object? entry in sent)
            () {
              final Map<String, Object?> update =
                  entry! as Map<String, Object?>;
              final Map<String, Object?> row = Map<String, Object?>.from(
                current.firstWhere(
                  (Map<String, Object?> a) => a['id'] == update['id'],
                  orElse: () => <String, Object?>{
                    'id': update['id'],
                    'filename': 'pic.png',
                    'size': 1024,
                    'flags': 0,
                    'url': 'https://cdn.fluxer.app/pic.png',
                    'proxy_url': 'https://cdn.fluxer.app/pic.png',
                    'content_type': 'image/png',
                    'description': null,
                  },
                ),
              );
              if (update.containsKey('description')) {
                row['description'] = update['description'];
              }
              return row;
            }(),
        ];
        _serverAttachments[edited.group(1)!] = next;
        _contentFor(edited.group(1)!);
        if (sentContent != null) {
          serverContent[edited.group(1)!] = sentContent;
        }
        return ResponseBody.fromString(
          jsonEncode(<String, Object?>{
            ..._messageJson(
              id: edited.group(1)!,
              channelId: _channelId,
              authorId: 'other',
              content: serverContent[edited.group(1)!],
            ),
            'attachments': next,
          }),
          200,
          headers: _jsonHeaders,
        );
      }
      return ResponseBody.fromString('Not found', 404);
    }
    if (options.method == 'DELETE') {
      final RegExpMatch? removed = RegExp(
        r'/channels/[^/]+/messages/([^/]+)/attachments/([^/]+)$',
      ).firstMatch(options.uri.path);
      if (removed != null) {
        attachmentRequests.add('DELETE ${removed.group(2)}');
      }
      if (holdDelete) {
        _deleteCompleter ??= Completer<void>();
        await _deleteCompleter!.future;
      }
      if (failDelete) {
        return ResponseBody.fromString('boom', 500);
      }
      if (removed != null) {
        _attachmentsFor(
          removed.group(1)!,
        ).removeWhere((Map<String, Object?> a) => a['id'] == removed.group(2));
      }
      return ResponseBody.fromString('', 204, statusMessage: 'No Content');
    }
    if (options.method == 'POST' && match != null) {
      final String? raw = await _readRequestBody(requestStream, options.data);
      final Map<String, dynamic> body = raw == null || raw.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(raw) as Map<String, dynamic>;
      if (holdSend) {
        _sendCompleter ??= Completer<void>();
        await _sendCompleter!.future;
      }
      return ResponseBody.fromString(
        jsonEncode(
          _messageJson(
            id: sentMessageId,
            channelId: _channelId,
            authorId: 'me',
            content: body['content'] as String? ?? '',
            nonce: body['nonce'] as String?,
          ),
        ),
        200,
        headers: _jsonHeaders,
      );
    }
    if (options.method != 'GET' || match == null) {
      return ResponseBody.fromString('Not found', 404);
    }
    final before = options.uri.queryParameters['before'];
    final after = options.uri.queryParameters['after'];
    final around = options.uri.queryParameters['around'];
    final int limit =
        int.tryParse(options.uri.queryParameters['limit'] ?? '') ?? 30;

    if (after != null) {
      afterFetchCalls++;
      if (holdAfterFetch) {
        _afterCompleter ??= Completer<void>();
        await _afterCompleter!.future;
      }
    }
    if (before != null) {
      olderFetchCalls++;
    }
    if (before != null && holdOlderFetch) {
      final Completer<void> completer = Completer<void>();
      _olderCompleters.add(completer);
      await completer.future;
    }
    if (around != null) {
      aroundFetchCalls++;
    }
    if (around != null && holdAroundFetch) {
      _aroundCompleter ??= Completer<void>();
      await _aroundCompleter!.future;
    }
    if (around != null && failAroundFetch) {
      return ResponseBody.fromString('boom', 500);
    }
    final bool isLatest = before == null && after == null && around == null;
    if (isLatest) {
      latestFetchCalls++;
    }
    if (isLatest && holdLatestFetch) {
      _latestCompleter ??= Completer<void>();
      await _latestCompleter!.future;
    }
    if (isLatest && failLatestFetch) {
      return ResponseBody.fromString('boom', 500);
    }

    final List<Map<String, Object?>> page;
    if (before != null) {
      final older = messages
          .where((m) => _compare(m['id']! as String, before) < 0)
          .toList();
      page = older.length <= limit
          ? older
          : older.sublist(older.length - limit);
    } else if (after != null) {
      final newer = messages
          .where((m) => _compare(m['id']! as String, after) > 0)
          .toList();
      page = newer.length <= limit ? newer : newer.sublist(0, limit);
    } else if (around != null) {
      var anchorIndex = messages.indexWhere((m) => m['id'] == around);
      if (anchorIndex == -1) {
        anchorIndex = messages.indexWhere(
          (m) => _compare(m['id']! as String, around) > 0,
        );
        if (anchorIndex == -1) {
          anchorIndex = messages.length - 1;
        }
      }
      final int halfLimit = limit ~/ 2;
      final int end = (anchorIndex + halfLimit + 1).clamp(0, messages.length);
      final int start = (end - limit).clamp(0, messages.length);
      page = messages.sublist(start, end);
    } else {
      page = messages.length <= limit
          ? messages
          : messages.sublist(messages.length - limit);
    }
    return ResponseBody.fromString(
      jsonEncode(page.reversed.toList()),
      200,
      headers: _jsonHeaders,
    );
  }

  static const Map<String, List<String>> _jsonHeaders = {
    Headers.contentTypeHeader: ['application/json'],
  };

  int _compare(String a, String b) => int.parse(a).compareTo(int.parse(b));

  @override
  void close({bool force = false}) {}
}

/// Pulls one named part out of a multipart body, `null` when it is absent.
String? _multipartField(String? body, String name) {
  if (body == null) {
    return null;
  }
  return RegExp(
    'name="$name"'
    r'\r?\n\r?\n(.*?)\r?\n--',
    dotAll: true,
  ).firstMatch(body)?.group(1);
}

/// Pulls the `attachments` part out of a multipart edit body.
List<Object?> _multipartAttachments(String? body) {
  if (body == null) {
    return const <Object?>[];
  }
  final RegExpMatch? part = RegExp(
    r'name="attachments"\r?\n\r?\n(.*?)\r?\n--',
    dotAll: true,
  ).firstMatch(body);
  if (part == null) {
    return const <Object?>[];
  }
  final Object? decoded = jsonDecode(part.group(1)!);
  return decoded is List<Object?> ? decoded : const <Object?>[];
}

Future<String?> _readRequestBody(
  Stream<Uint8List>? requestStream,
  dynamic data,
) async {
  if (requestStream != null) {
    final List<Uint8List> chunks = await requestStream.toList();
    if (chunks.isEmpty) {
      return null;
    }
    final int totalLength = chunks.fold<int>(0, (int sum, c) => sum + c.length);
    final Uint8List bytes = Uint8List(totalLength);
    var offset = 0;
    for (final Uint8List chunk in chunks) {
      bytes.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    return utf8.decode(bytes);
  }
  if (data is String) {
    return data;
  }
  if (data is Map<String, dynamic>) {
    return jsonEncode(data);
  }
  return null;
}
