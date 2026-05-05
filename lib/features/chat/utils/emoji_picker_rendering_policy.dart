const int kEmojiPickerOverscanRows = 2;

double emojiPickerCacheExtent({
  required double rowHeight,
  int overscanRows = kEmojiPickerOverscanRows,
}) => rowHeight * overscanRows;

bool emojiPickerUsesHoverTracking({required bool isMobile}) => !isMobile;

bool emojiPickerShouldBuildUpsell({
  required bool isPremium,
  required bool hasSearchQuery,
  required bool isFirstFrameSettled,
}) => !isPremium && !hasSearchQuery && isFirstFrameSettled;
