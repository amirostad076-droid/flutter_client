/// Read-viewport and pagination decisions during sticky-unread review mode.

const double kMessageListReadBottomThreshold = 48.0;

bool isInUnreadReview({
  required String? stickyUnreadMessageId,
  required bool initialUnreadPivotReleased,
}) {
  return stickyUnreadMessageId != null && !initialUnreadPivotReleased;
}

bool isNearScrollExtentEnd({
  required double pixels,
  required double minScrollExtent,
  double threshold = kMessageListReadBottomThreshold,
}) {
  return (pixels - minScrollExtent) <= threshold;
}

bool shouldReleaseUnreadReviewOnScrollEnd({
  required bool inUnreadReview,
  required double pixels,
  required double minScrollExtent,
  double threshold = kMessageListReadBottomThreshold,
}) {
  return inUnreadReview &&
      isNearScrollExtentEnd(
        pixels: pixels,
        minScrollExtent: minScrollExtent,
        threshold: threshold,
      );
}

bool shouldClearPivotOnUnreadReviewRelease({
  required bool hasMoreNewerMessages,
}) {
  return !hasMoreNewerMessages;
}

bool shouldMigratePivotDuringUnreadReview({required bool inUnreadReview}) {
  return false;
}

bool canTriggerLoadNewerDuringUnreadReview({required bool inUnreadReview}) {
  return !inUnreadReview;
}

bool reportIsNearBottomForReadViewport({
  required bool inUnreadReview,
  required bool liveNearBottom,
}) {
  if (inUnreadReview) {
    return false;
  }
  return liveNearBottom;
}

bool isLiveNearBottom({
  required double pixels,
  required double minScrollExtent,
  double threshold = kMessageListReadBottomThreshold,
}) {
  return isNearScrollExtentEnd(
    pixels: pixels,
    minScrollExtent: minScrollExtent,
    threshold: threshold,
  );
}
