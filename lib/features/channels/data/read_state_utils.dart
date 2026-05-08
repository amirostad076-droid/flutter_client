import 'package:fluxer_app/shared/utils/snowflake_time.dart';

const Duration oldMessageUnreadThreshold = Duration(days: 7);
const Duration recentReadThreshold = Duration(days: 3);

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

bool hasUnreadByReadState({
  required String? channelLastMessageId,
  required String? ackLastMessageId,
  required int fallbackAckMs,
  required int mentionCount,
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

bool canShowMentionCount({
  required String? channelLastMessageId,
  required bool isGuildChannel,
  required DateTime now,
}) {
  if (!isGuildChannel) {
    return true;
  }
  final lastMessageMs = snowflakeTimestampMs(channelLastMessageId);
  if (lastMessageMs <= 0) {
    return true;
  }
  return lastMessageMs >=
      now.millisecondsSinceEpoch - oldMessageUnreadThreshold.inMilliseconds;
}

bool shouldSuppressStaleUnread({
  required String? channelLastMessageId,
  required String? ackLastMessageId,
  required int fallbackAckMs,
  required int mentionCount,
  required DateTime now,
}) {
  if (mentionCount > 0) {
    return false;
  }

  final lastMessageMs = snowflakeTimestampMs(channelLastMessageId);
  if (lastMessageMs <= 0) {
    return false;
  }

  if (lastMessageMs >=
      now.millisecondsSinceEpoch - oldMessageUnreadThreshold.inMilliseconds) {
    return false;
  }

  final ackMs = ackLastMessageId != null && ackLastMessageId.isNotEmpty
      ? snowflakeTimestampMs(ackLastMessageId)
      : fallbackAckMs;
  return ackMs <=
      now.millisecondsSinceEpoch - recentReadThreshold.inMilliseconds;
}
