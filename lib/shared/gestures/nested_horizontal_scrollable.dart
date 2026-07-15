import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Returns true when [globalPosition] hit tests an overflowing horizontal
/// scroll viewport (wide markdown table) within [searchRoot].
bool isPointerOverOverflowingHorizontalScrollable(
  BuildContext searchRoot,
  Offset globalPosition, {
  required int viewId,
}) {
  final HitTestResult result = HitTestResult();
  WidgetsBinding.instance.hitTestInView(result, globalPosition, viewId);
  for (final HitTestEntry entry in result.path) {
    if (entry.target is! RenderObject) {
      continue;
    }
    if (_horizontalScrollPositionForHit(
          entry.target as RenderObject,
          searchRoot,
        ) !=
        null) {
      return true;
    }
  }
  return false;
}

ScrollPosition? _horizontalScrollPositionForHit(
  RenderObject hit,
  BuildContext searchRoot,
) {
  ScrollPosition? matched;
  void visit(Element element) {
    if (matched != null) {
      return;
    }
    final State<StatefulWidget>? state = switch (element) {
      StatefulElement(:final State<StatefulWidget> state) => state,
      _ => null,
    };
    if (state is ScrollableState &&
        state.widget.axis == Axis.horizontal &&
        state.position.maxScrollExtent > 0) {
      final RenderObject? scrollableRender = state.context.findRenderObject();
      if (scrollableRender != null &&
          _isRenderDescendantOf(hit, scrollableRender)) {
        matched = state.position;
      }
    }
    element.visitChildren(visit);
  }

  visit(searchRoot as Element);
  return matched;
}

bool _isRenderDescendantOf(RenderObject descendant, RenderObject ancestor) {
  RenderObject? current = descendant;
  while (current != null) {
    if (current == ancestor) {
      return true;
    }
    current = current.parent;
  }
  return false;
}
