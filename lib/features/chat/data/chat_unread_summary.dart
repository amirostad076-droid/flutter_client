import 'package:fluxer_app/features/channels/data/read_state_utils.dart';

class ChatUnreadMessageRef {
  const ChatUnreadMessageRef({required this.id, required this.authorId});

  final String id;
  final String authorId;
}

class ChatUnreadSummary {
  const ChatUnreadSummary({
    required this.oldestUnreadMessageId,
    required this.loadedUnreadCount,
    required this.displayUnreadCount,
    required this.isEstimated,
  });

  final String? oldestUnreadMessageId;
  final int loadedUnreadCount;
  final int displayUnreadCount;
  final bool isEstimated;

  bool get hasUnread => displayUnreadCount > 0;
}

ChatUnreadSummary computeChatUnreadSummary({
  required Iterable<ChatUnreadMessageRef> messages,
  required String? ackLastMessageId,
  required int mentionCount,
  required String? currentUserId,
}) {
  if (ackLastMessageId == null || ackLastMessageId.isEmpty) {
    return const ChatUnreadSummary(
      oldestUnreadMessageId: null,
      loadedUnreadCount: 0,
      displayUnreadCount: 0,
      isEstimated: false,
    );
  }

  String? oldestUnread;
  var loadedUnreadCount = 0;
  var hasLoadedAckBoundary = false;

  for (final message in messages) {
    final comparison = compareSnowflakeIds(message.id, ackLastMessageId);
    if (comparison <= 0) {
      hasLoadedAckBoundary = true;
      continue;
    }
    if (currentUserId != null &&
        currentUserId.isNotEmpty &&
        message.authorId == currentUserId) {
      continue;
    }
    oldestUnread ??= message.id;
    loadedUnreadCount++;
  }

  final displayUnreadCount = loadedUnreadCount > mentionCount
      ? loadedUnreadCount
      : mentionCount;

  return ChatUnreadSummary(
    oldestUnreadMessageId: oldestUnread,
    loadedUnreadCount: loadedUnreadCount,
    displayUnreadCount: displayUnreadCount,
    isEstimated: displayUnreadCount > 0 && !hasLoadedAckBoundary,
  );
}
