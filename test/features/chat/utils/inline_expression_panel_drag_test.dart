import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/chat/utils/inline_expression_panel_drag.dart';

void main() {
  test('drags downward from expanded panel shrink the panel', () {
    expect(
      inlineExpressionPanelHeightAfterDrag(
        currentHeight: 600,
        deltaDy: 80,
        minHeight: 175,
        maxHeight: 700,
      ),
      520,
    );
  });

  test('drags upward grow the panel', () {
    expect(
      inlineExpressionPanelHeightAfterDrag(
        currentHeight: 350,
        deltaDy: -80,
        minHeight: 175,
        maxHeight: 700,
      ),
      430,
    );
  });

  test('height is clamped to the available range', () {
    expect(
      inlineExpressionPanelHeightAfterDrag(
        currentHeight: 200,
        deltaDy: 80,
        minHeight: 175,
        maxHeight: 700,
      ),
      175,
    );
    expect(
      inlineExpressionPanelHeightAfterDrag(
        currentHeight: 680,
        deltaDy: -80,
        minHeight: 175,
        maxHeight: 700,
      ),
      700,
    );
  });
}
