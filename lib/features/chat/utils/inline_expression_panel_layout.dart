import 'dart:math' as math;

const double kInlineExpressionPanelCollapsedHeight = 350;

double inlineExpressionPanelMaxHeight({
  required double availableHeight,
  required double screenHeight,
  required double keyboardInset,
  required double topPadding,
  required double topMargin,
}) {
  final keyboardSafeHeight =
      screenHeight - keyboardInset - topPadding - topMargin;
  return math.max(0, math.min(availableHeight, keyboardSafeHeight));
}

double inlineExpressionPanelExpandedHeight({
  required double availableHeight,
  required double screenHeight,
  required double keyboardInset,
  required double topPadding,
  required double topMargin,
  required double expandedFraction,
}) {
  final maxHeight = inlineExpressionPanelMaxHeight(
    availableHeight: availableHeight,
    screenHeight: screenHeight,
    keyboardInset: keyboardInset,
    topPadding: topPadding,
    topMargin: topMargin,
  );
  return math.min(maxHeight, screenHeight * expandedFraction);
}
