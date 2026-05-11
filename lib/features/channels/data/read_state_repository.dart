import 'package:drift/drift.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/features/channels/data/read_state_utils.dart';
import 'package:fluxer_app/features/channels/data/unread_settings_resolver.dart';
import 'package:fluxer_dart/export.dart';

class ReadStateRepository {
  const ReadStateRepository(this._client, this._db);

  final FluxerClient _client;
  final FluxerDatabase _db;

  Future<void> ackLatest(String channelId) async {
    final messageId = await applyLocalAckLatest(channelId);
    if (messageId == null) {
      return;
    }
    await sendAckHttp(channelId, messageId);
  }

  Future<String?> applyLocalAckLatest(String channelId) async {
    final messageId = await latestAckableMessageId(channelId);
    if (messageId == null || messageId.isEmpty) {
      return null;
    }

    final current = await _db.readStateDao.getReadState(channelId);
    if (current?.lastMessageId == messageId &&
        current?.mentionCount == 0 &&
        current?.manual != true) {
      return null;
    }

    await applyLocalAck(
      channelId: channelId,
      messageId: messageId,
      mentionCount: 0,
    );
    return messageId;
  }

  Future<void> sendAckHttp(String channelId, String messageId) =>
      _client.channels.acknowledgeMessage(
        channelId: channelId,
        messageId: messageId,
        body: const MessageAckRequest(),
      );

  Future<void> ackLatestBulk(Iterable<String> channelIds) async {
    final entries = <ReadStateAckBulkRequestReadStates>[];
    for (final channelId in channelIds.toSet()) {
      final messageId = await latestAckableMessageId(channelId);
      if (messageId == null || messageId.isEmpty) {
        continue;
      }

      final current = await _db.readStateDao.getReadState(channelId);
      if (current?.lastMessageId == messageId &&
          current?.mentionCount == 0 &&
          current?.manual != true) {
        continue;
      }

      entries.add(
        ReadStateAckBulkRequestReadStates(
          channelId: channelId,
          messageId: messageId,
        ),
      );
    }

    if (entries.isEmpty) {
      return;
    }

    for (final entry in entries) {
      await applyLocalAck(
        channelId: entry.channelId,
        messageId: entry.messageId,
        mentionCount: 0,
      );
    }

    await _client.readStates.ackBulkMessages(
      body: ReadStateAckBulkRequest(readStates: entries),
    );
  }

  Future<void> applyLocalAck({
    required String channelId,
    required String messageId,
    required int mentionCount,
    bool manual = false,
  }) async {
    await _db.readStateDao.upsertReadState(
      ReadStatesCompanion(
        channelId: Value(channelId),
        lastMessageId: Value(messageId),
        mentionCount: Value(mentionCount),
        manual: Value(manual),
      ),
    );
    final dm = await _db.dmChannelDao.getDmChannelById(channelId);
    if (dm != null) {
      await _db.dmChannelDao.updateUnreadCount(channelId, mentionCount);
    }
  }

  Future<void> markMessageUnread({
    required String channelId,
    required String messageId,
    required String? currentUserId,
  }) async {
    final ackMessageId = await _previousMessageId(channelId, messageId);
    if (ackMessageId == null || ackMessageId.isEmpty) {
      return;
    }

    final mentionCount = await _computeMentionCountAfterAck(
      channelId: channelId,
      ackMessageId: ackMessageId,
      currentUserId: currentUserId,
    );

    await _client.channels.acknowledgeMessage(
      channelId: channelId,
      messageId: ackMessageId,
      body: MessageAckRequest(mentionCount: mentionCount, manual: true),
    );
    await applyLocalAck(
      channelId: channelId,
      messageId: ackMessageId,
      mentionCount: mentionCount,
      manual: true,
    );
  }

  Future<void> cleanupStaleReadStates({
    int maxConcurrentHttp = 3,
    int maxConsecutiveFailures = 5,
  }) async {
    final readStates = await _db.readStateDao.getReadStates();
    final staleChannelIds = <String>[];
    for (final readState in readStates) {
      final channel = await _db.channelDao.getChannelById(readState.channelId);
      if (channel != null) {
        continue;
      }
      final dm = await _db.dmChannelDao.getDmChannelById(readState.channelId);
      if (dm == null) {
        staleChannelIds.add(readState.channelId);
      }
    }
    if (staleChannelIds.isEmpty) {
      return;
    }
    staleChannelIds.sort();

    await _db.transaction(() async {
      for (final channelId in staleChannelIds) {
        await _db.readStateDao.deleteReadState(channelId);
      }
    });

    var consecutiveFailures = 0;
    for (var i = 0; i < staleChannelIds.length; i += maxConcurrentHttp) {
      final end = (i + maxConcurrentHttp).clamp(0, staleChannelIds.length);
      final chunk = staleChannelIds.sublist(i, end);
      final results = await Future.wait(
        chunk.map((channelId) async {
          try {
            await _client.channels.clearChannelReadState(channelId: channelId);
            return true;
          } on Exception {
            return false;
          }
        }),
      );
      for (final ok in results) {
        if (ok) {
          consecutiveFailures = 0;
        } else {
          consecutiveFailures++;
          if (consecutiveFailures >= maxConsecutiveFailures) {
            return;
          }
        }
      }
    }
  }

  Future<void> ackPins(String channelId) async {
    final channel = await _db.channelDao.getChannelById(channelId);
    final latestPinTimestamp = channel?.lastPinTimestamp;
    if (latestPinTimestamp == null || latestPinTimestamp.isEmpty) {
      return;
    }

    final current = await _db.readStateDao.getReadState(channelId);
    if (current?.lastPinTimestamp == latestPinTimestamp) {
      return;
    }

    await _client.channels.acknowledgePins(channelId: channelId);
    await _db.readStateDao.updatePinTimestamp(channelId, latestPinTimestamp);
  }

  Future<String?> latestAckableMessageId(String channelId) async {
    final channel = await _db.channelDao.getChannelById(channelId);
    final channelLastMessageId = channel?.lastMessageId;
    final cachedLastMessageId = (await _db.messageDao.getLastMessage(
      channelId,
    ))?.id;

    if (channelLastMessageId != null && channelLastMessageId.isNotEmpty) {
      if (cachedLastMessageId != null && cachedLastMessageId.isNotEmpty) {
        return compareSnowflakeIds(cachedLastMessageId, channelLastMessageId) >
                0
            ? cachedLastMessageId
            : channelLastMessageId;
      }
      return channelLastMessageId;
    }

    if (cachedLastMessageId != null && cachedLastMessageId.isNotEmpty) {
      return cachedLastMessageId;
    }

    return (await _db.readStateDao.getReadState(channelId))?.lastMessageId;
  }

  Future<String?> _previousMessageId(String channelId, String messageId) async {
    final previous = await _db.messageDao.getPreviousMessage(
      channelId,
      messageId,
    );
    if (previous != null) {
      return previous.id;
    }
    final reference = await _db.messageDao.getMessage(messageId);
    if (reference != null) {
      return snowflakeAtPreviousMillisecond(messageId);
    }
    return null;
  }

  Future<int> _computeMentionCountAfterAck({
    required String channelId,
    required String ackMessageId,
    required String? currentUserId,
  }) async {
    final isDm = await _db.dmChannelDao.getDmChannelById(channelId) != null;
    if (isDm && await _isDmMuted(channelId)) {
      return 0;
    }
    final blockedUserIds = await _db.relationshipDao.getBlockedUserIds();
    final messages = await _db.messageDao.getMessages(channelId, limit: 1000);
    var mentionCount = 0;
    for (final message in messages) {
      if (compareSnowflakeIds(message.id, ackMessageId) <= 0) {
        continue;
      }
      if (blockedUserIds.contains(message.authorId)) {
        continue;
      }
      if (isDm) {
        if (currentUserId == null || message.authorId != currentUserId) {
          mentionCount++;
        }
      } else if (message.isMentioned) {
        mentionCount++;
      }
    }
    return mentionCount;
  }

  Future<bool> _isDmMuted(String channelId) async {
    final settingsRow = await _db.userGuildSettingsDao.getByGuildId('@me');
    final settings = settingsRow == null
        ? null
        : decodeUserGuildSettings(settingsRow.data);
    return isChannelOverrideMuted(
      settings?.channelOverrides?[channelId],
      now: DateTime.now(),
    );
  }
}
