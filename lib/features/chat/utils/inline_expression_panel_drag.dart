double inlineExpressionPanelHeightAfterDrag({
  required double currentHeight,
  required double deltaDy,
  required double minHeight,
  required double maxHeight,
}) => (currentHeight - deltaDy).clamp(minHeight, maxHeight);

double inlineExpressionPanelHeightAfterScrollExpansion({
  required double currentHeight,
  required double scrollDelta,
  required double minHeight,
  required double maxHeight,
}) => (currentHeight + scrollDelta).clamp(minHeight, maxHeight);

double inlineExpressionPanelHeightAfterTopOverscroll({
  required double currentHeight,
  required double overscroll,
  required double minHeight,
  required double maxHeight,
}) => (currentHeight + overscroll).clamp(minHeight, maxHeight);

bool inlineExpressionPanelShouldHandleTopOverscroll({
  required double pixels,
  required double minScrollExtent,
  required double overscroll,
}) => overscroll < 0 && pixels <= minScrollExtent + 0.5;
