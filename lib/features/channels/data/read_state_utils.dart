import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/shared/utils/snowflake_time.dart';

final BigInt _zeroSnowflake = BigInt.zero;

int compareSnowflakeIds(String? a, String? b) {
  final ai = BigInt.tryParse(a ?? '') ?? _zeroSnowflake;
  final bi = BigInt.tryParse(b ?? '') ?? _zeroSnowflake;
  return ai.compareTo(bi);
}

int snowflakeTimestampMs(String? id) {
  final parsed = BigInt.tryParse(id ?? '');
  if (parsed == null) {
    return 0;
  }
  return (parsed >> 22).toInt() + kSnowflakeEpochMs;
}

String snowflakeAtPreviousMillisecond(String id) {
  final timestampMs = snowflakeTimestampMs(id);
  if (timestampMs <= kSnowflakeEpochMs) {
    return '0';
  }
  return (BigInt.from(timestampMs - kSnowflakeEpochMs - 1) << 22).toString();
}

String? resolveLatestMessageId({
  required String? channelLastMessageId,
  required String? cachedLastMessageId,
  required bool channelLastMessageExistsInCache,
}) {
  if (cachedLastMessageId != null && cachedLastMessageId.isNotEmpty) {
    return cachedLastMessageId;
  }
  if (channelLastMessageId != null &&
      channelLastMessageId.isNotEmpty &&
      channelLastMessageExistsInCache) {
    return channelLastMessageId;
  }
  return null;
}

Future<String?> resolveLatestMessageIdForChannel(
  FluxerDatabase db,
  String channelId, {
  String? channelLastMessageId,
}) async {
  final lastCachedMessage = await db.messageDao.getLastMessage(channelId);
  var channelLastExists = false;
  if (channelLastMessageId != null && channelLastMessageId.isNotEmpty) {
    channelLastExists =
        await db.messageDao.getMessage(channelLastMessageId) != null;
  }
  return resolveLatestMessageId(
    channelLastMessageId: channelLastMessageId,
    cachedLastMessageId: lastCachedMessage?.id,
    channelLastMessageExistsInCache: channelLastExists,
  );
}

String? resolveLatestMessageIdForUnread({
  required String? strictLatestMessageId,
  required String? channelLastMessageId,
  required String? ackLastMessageId,
  required int mentionCount,
}) {
  if (strictLatestMessageId != null && strictLatestMessageId.isNotEmpty) {
    if (channelLastMessageId != null &&
        channelLastMessageId.isNotEmpty &&
        compareSnowflakeIds(strictLatestMessageId, channelLastMessageId) < 0 &&
        (ackLastMessageId == null ||
            ackLastMessageId.isEmpty ||
            compareSnowflakeIds(ackLastMessageId, channelLastMessageId) < 0)) {
      return channelLastMessageId;
    }
    return strictLatestMessageId;
  }
  if (channelLastMessageId == null || channelLastMessageId.isEmpty) {
    return null;
  }
  if (mentionCount > 0) {
    return channelLastMessageId;
  }
  if (ackLastMessageId == null || ackLastMessageId.isEmpty) {
    return channelLastMessageId;
  }
  if (compareSnowflakeIds(ackLastMessageId, channelLastMessageId) < 0) {
    return channelLastMessageId;
  }
  return null;
}

Future<String?> resolveLatestMessageIdForUnreadDisplay(
  FluxerDatabase db,
  String channelId, {
  String? channelLastMessageId,
  String? ackLastMessageId,
  int mentionCount = 0,
}) async {
  final strictLatestMessageId = await resolveLatestMessageIdForChannel(
    db,
    channelId,
    channelLastMessageId: channelLastMessageId,
  );
  return resolveLatestMessageIdForUnread(
    strictLatestMessageId: strictLatestMessageId,
    channelLastMessageId: channelLastMessageId,
    ackLastMessageId: ackLastMessageId,
    mentionCount: mentionCount,
  );
}

bool hasUnreadByReadState({
  required String? channelLastMessageId,
  required String? ackLastMessageId,
  required int fallbackAckMs,
  required int mentionCount,
  bool isGuildChannel = false,
}) {
  if (mentionCount > 0) {
    return true;
  }

  if (channelLastMessageId == null || channelLastMessageId.isEmpty) {
    return false;
  }

  if (ackLastMessageId != null && ackLastMessageId.isNotEmpty) {
    return compareSnowflakeIds(ackLastMessageId, channelLastMessageId) < 0;
  }

  if (isGuildChannel) {
    return false;
  }

  if (fallbackAckMs <= 0) {
    return false;
  }

  final lastMessageMs = snowflakeTimestampMs(channelLastMessageId);
  return lastMessageMs > 0 && lastMessageMs > fallbackAckMs;
}

int parseIsoTimestampMs(String? timestamp) {
  if (timestamp == null || timestamp.isEmpty) {
    return 0;
  }
  return DateTime.tryParse(timestamp)?.millisecondsSinceEpoch ?? 0;
}

int dmUnreadCountFromReadState({
  required String? latestMessageId,
  required String? ackLastMessageId,
  required int fallbackAckMs,
  required int mentionCount,
  required int cachedUnreadCount,
}) {
  if (mentionCount > 0) {
    return mentionCount;
  }
  if (latestMessageId == null || latestMessageId.isEmpty) {
    return cachedUnreadCount;
  }
  final hasUnread = hasUnreadByReadState(
    channelLastMessageId: latestMessageId,
    ackLastMessageId: ackLastMessageId,
    fallbackAckMs: fallbackAckMs,
    mentionCount: 0,
  );
  if (hasUnread) {
    return 1;
  }
  return 0;
}

bool hasUnreadPins({
  required String? channelLastPinTimestamp,
  required String? ackLastPinTimestamp,
}) {
  final lastPinMs = parseIsoTimestampMs(channelLastPinTimestamp);
  if (lastPinMs <= 0) {
    return false;
  }
  return lastPinMs > parseIsoTimestampMs(ackLastPinTimestamp);
}

String? oldestUnreadMessageId({
  required Iterable<String> messageIds,
  required String? ackLastMessageId,
}) {
  if (ackLastMessageId == null || ackLastMessageId.isEmpty) {
    return null;
  }

  for (final messageId in messageIds) {
    if (compareSnowflakeIds(messageId, ackLastMessageId) > 0) {
      return messageId;
    }
  }

  return null;
}

/// True if the DM-relevant read-state fields (ack id + mention count) differ
/// between two channelId->ReadState snapshots. Used to skip recomputes that
/// Drift's table-level stream invalidation fires when no relevant read state
/// actually changed.
bool dmReadStatesChanged(
  Map<String, ReadState> previous,
  Map<String, ReadState> next,
) {
  if (previous.length != next.length) {
    return true;
  }
  for (final entry in next.entries) {
    final prior = previous[entry.key];
    if (prior == null ||
        prior.lastMessageId != entry.value.lastMessageId ||
        prior.mentionCount != entry.value.mentionCount) {
      return true;
    }
  }
  return false;
}
