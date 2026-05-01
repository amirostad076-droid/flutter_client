double inlineExpressionPanelHeightAfterDrag({
  required double currentHeight,
  required double deltaDy,
  required double minHeight,
  required double maxHeight,
}) => (currentHeight - deltaDy).clamp(minHeight, maxHeight);
