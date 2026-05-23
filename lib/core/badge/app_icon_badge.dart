/// OS app-icon badge value derived from unread state
class AppIconBadgeValue {
  const AppIconBadgeValue({required this.count});

  /// `0` clears the badge; `1`+ sets the launcher count.
  final int count;
}

/// Default matches web Notification.unreadMessageBadgeEnabled.
const bool kDefaultUnreadMessageBadgeEnabled = true;

/// Computes the app-icon badge count
AppIconBadgeValue computeAppIconBadge({
  required int guildMentionCount,
  required int dmMentionCount,
  required int pendingFriendRequestCount,
  required bool guildHasPlainUnread,
  required bool dmHasPlainUnread,
  bool unreadMessageBadgeEnabled = kDefaultUnreadMessageBadgeEnabled,
}) {
  final int mentionTotal = guildMentionCount + dmMentionCount;
  final int totalCount = mentionTotal + pendingFriendRequestCount;
  if (totalCount > 0) {
    return AppIconBadgeValue(count: totalCount);
  }
  final bool hasPlainUnread = guildHasPlainUnread || dmHasPlainUnread;
  if (hasPlainUnread && unreadMessageBadgeEnabled) {
    return const AppIconBadgeValue(count: 1);
  }
  return const AppIconBadgeValue(count: 0);
}

/// Whether a guild entry contributes plain unread (not mentions).
bool guildEntryHasPlainUnread({
  required bool hasUnread,
  required int mentionCount,
}) => hasUnread && mentionCount == 0;
