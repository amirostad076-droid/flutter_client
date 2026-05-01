import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/chat/utils/inline_expression_panel_layout.dart';

void main() {
  test('caps panel height to visible area above the keyboard', () {
    expect(
      inlineExpressionPanelMaxHeight(
        availableHeight: 800,
        screenHeight: 800,
        keyboardInset: 320,
        topPadding: 24,
        topMargin: 8,
      ),
      448,
    );
  });

  test('uses parent constraints when the scaffold already resized', () {
    expect(
      inlineExpressionPanelMaxHeight(
        availableHeight: 460,
        screenHeight: 800,
        keyboardInset: 320,
        topPadding: 24,
        topMargin: 8,
      ),
      448,
    );
  });

  test('clamps expanded height to the keyboard safe maximum', () {
    expect(
      inlineExpressionPanelExpandedHeight(
        availableHeight: 800,
        screenHeight: 800,
        keyboardInset: 320,
        topPadding: 24,
        topMargin: 8,
        expandedFraction: 0.85,
      ),
      448,
    );
  });

  test('anchors the panel above an open keyboard', () {
    expect(inlineExpressionPanelBottomOffset(keyboardInset: 320), 320);
    expect(inlineExpressionPanelBottomOffset(keyboardInset: 0), 0);
  });
}
