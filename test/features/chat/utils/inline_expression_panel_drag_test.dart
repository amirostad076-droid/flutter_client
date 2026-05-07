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

  test('positive scroll overscroll grows a collapsed panel', () {
    expect(
      inlineExpressionPanelHeightAfterScrollExpansion(
        currentHeight: 350,
        scrollDelta: 80,
        minHeight: 350,
        maxHeight: 700,
      ),
      430,
    );
  });

  test('scroll expansion is clamped to the available range', () {
    expect(
      inlineExpressionPanelHeightAfterScrollExpansion(
        currentHeight: 680,
        scrollDelta: 80,
        minHeight: 350,
        maxHeight: 700,
      ),
      700,
    );
  });

  test('top overscroll can shrink below the collapsed height', () {
    expect(
      inlineExpressionPanelHeightAfterTopOverscroll(
        currentHeight: 350,
        overscroll: -120,
        minHeight: 175,
        maxHeight: 700,
      ),
      230,
    );
  });

  test('top overscroll only starts at the scrollable start', () {
    expect(
      inlineExpressionPanelShouldHandleTopOverscroll(
        pixels: 0,
        minScrollExtent: 0,
        overscroll: -20,
      ),
      isTrue,
    );
    expect(
      inlineExpressionPanelShouldHandleTopOverscroll(
        pixels: 12,
        minScrollExtent: 0,
        overscroll: -20,
      ),
      isFalse,
    );
    expect(
      inlineExpressionPanelShouldHandleTopOverscroll(
        pixels: 0,
        minScrollExtent: 0,
        overscroll: 20,
      ),
      isFalse,
    );
  });
}
