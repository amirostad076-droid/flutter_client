class DmUnreadIndicatorState {
  const DmUnreadIndicatorState({required this.show, this.faded = false});

  static const hidden = DmUnreadIndicatorState(show: false);

  final bool show;
  final bool faded;
}

DmUnreadIndicatorState computeDmUnreadIndicator({
  required int unreadCount,
  required int mentionCount,
  required bool isMuted,
  required bool showFadedUnreadOnMutedChannels,
}) {
  if (unreadCount <= 0 && mentionCount <= 0) {
    return DmUnreadIndicatorState.hidden;
  }
  if (isMuted) {
    if (!showFadedUnreadOnMutedChannels) {
      return DmUnreadIndicatorState.hidden;
    }
    return const DmUnreadIndicatorState(show: true, faded: true);
  }
  return const DmUnreadIndicatorState(show: true);
}
