import 'package:fluxer_dart/export.dart';

class ChannelUnreadState {
  const ChannelUnreadState({
    required this.hasUnreadMessages,
    required this.hasMentions,
    required this.isHighlight,
    required this.shouldShowUnreadIndicator,
    required this.hasVisibleUnread,
  });

  final bool hasUnreadMessages;
  final bool hasMentions;
  final bool isHighlight;
  final bool shouldShowUnreadIndicator;
  final bool hasVisibleUnread;
}

ChannelUnreadState getChannelUnreadState({
  required int unreadCount,
  required int mentionCount,
  required bool isMuted,
  required bool showFadedUnreadOnMutedChannels,
  UserNotificationSettings? unreadBadgesLevel,
}) {
  final bool hasUnreadMessages = unreadCount > 0;
  final bool rawHasMentions = mentionCount > 0;
  final bool shouldShowUnreadIndicator;
  final bool isHighlight;
  final bool mentionsVisible;
  if (unreadBadgesLevel == UserNotificationSettings.noMessages) {
    shouldShowUnreadIndicator = false;
    mentionsVisible = false;
    isHighlight = false;
  } else if (unreadBadgesLevel == UserNotificationSettings.onlyMentions) {
    shouldShowUnreadIndicator = false;
    mentionsVisible = rawHasMentions;
    isHighlight = rawHasMentions;
  } else if (unreadBadgesLevel == UserNotificationSettings.allMessages) {
    shouldShowUnreadIndicator = hasUnreadMessages;
    mentionsVisible = rawHasMentions;
    isHighlight = rawHasMentions || hasUnreadMessages;
  } else {
    shouldShowUnreadIndicator =
        hasUnreadMessages && (!isMuted || showFadedUnreadOnMutedChannels);
    mentionsVisible = rawHasMentions;
    isHighlight = rawHasMentions || (hasUnreadMessages && !isMuted);
  }
  return ChannelUnreadState(
    hasUnreadMessages: hasUnreadMessages,
    hasMentions: mentionsVisible,
    isHighlight: isHighlight,
    shouldShowUnreadIndicator: shouldShowUnreadIndicator,
    hasVisibleUnread: mentionsVisible || shouldShowUnreadIndicator,
  );
}
