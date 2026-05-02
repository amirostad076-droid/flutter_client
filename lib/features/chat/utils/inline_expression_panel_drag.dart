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
