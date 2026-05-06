import 'package:drift/drift.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/features/channels/data/read_state_utils.dart';
import 'package:fluxer_dart/export.dart';

class ReadStateRepository {
  const ReadStateRepository(this._client, this._db);

  final FluxerClient _client;
  final FluxerDatabase _db;

  Future<void> ackLatest(String channelId) async {
    final messageId = await latestAckableMessageId(channelId);
    if (messageId == null || messageId.isEmpty) {
      return;
    }

    final current = await _db.readStateDao.getReadState(channelId);
    if (current?.lastMessageId == messageId && current?.mentionCount == 0) {
      await _db.dmChannelDao.markAsRead(channelId);
      return;
    }

    await applyLocalAck(
      channelId: channelId,
      messageId: messageId,
      mentionCount: 0,
    );
    await _client.channels.acknowledgeMessage(
      channelId: channelId,
      messageId: messageId,
      body: const MessageAckRequest(),
    );
  }

  Future<void> applyLocalAck({
    required String channelId,
    required String messageId,
    required int mentionCount,
  }) async {
    await _db.readStateDao.upsertReadState(
      ReadStatesCompanion(
        channelId: Value(channelId),
        lastMessageId: Value(messageId),
        mentionCount: Value(mentionCount),
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
    );
  }

  Future<void> cleanupStaleReadStates({
    Duration delayBetweenDeletes = const Duration(milliseconds: 300),
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
    staleChannelIds.sort();

    for (var i = 0; i < staleChannelIds.length; i++) {
      final channelId = staleChannelIds[i];
      try {
        await _client.channels.clearChannelReadState(channelId: channelId);
      } finally {
        await _db.readStateDao.deleteReadState(channelId);
      }
      if (delayBetweenDeletes > Duration.zero &&
          i < staleChannelIds.length - 1) {
        await Future<void>.delayed(delayBetweenDeletes);
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
    if (channelLastMessageId != null && channelLastMessageId.isNotEmpty) {
      return channelLastMessageId;
    }

    final messages = await _db.messageDao.getMessages(channelId, limit: 1);
    if (messages.isNotEmpty) {
      return messages.last.id;
    }

    return (await _db.readStateDao.getReadState(channelId))?.lastMessageId;
  }

  Future<String?> _previousMessageId(String channelId, String messageId) async {
    final messages = await _db.messageDao.getMessages(channelId, limit: 1000);
    final index = messages.indexWhere((m) => m.id == messageId);
    if (index > 0) {
      return messages[index - 1].id;
    }
    if (index == 0) {
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
    final messages = await _db.messageDao.getMessages(channelId, limit: 1000);
    var mentionCount = 0;
    for (final message in messages) {
      if (compareSnowflakeIds(message.id, ackMessageId) <= 0) {
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
}
