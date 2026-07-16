import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';

const double kExpandableSheetSnapMidpointFraction = 0.42;
const double kExpandableSheetFlingVelocityThreshold = 650;

Duration expandableSheetSnapDuration(
  BuildContext context, {
  required bool isDragging,
}) {
  if (isDragging || MediaQuery.disableAnimationsOf(context)) {
    return Duration.zero;
  }
  return context.motion.slow;
}

double expandableSheetBinarySnapHeight({
  required double currentHeight,
  required double velocity,
  required double collapsedHeight,
  required double expandedHeight,
}) {
  final double midpoint =
      collapsedHeight +
      ((expandedHeight - collapsedHeight) *
          kExpandableSheetSnapMidpointFraction);
  if (velocity < -kExpandableSheetFlingVelocityThreshold) {
    return expandedHeight;
  }
  if (velocity > kExpandableSheetFlingVelocityThreshold) {
    return collapsedHeight;
  }
  return currentHeight >= midpoint ? expandedHeight : collapsedHeight;
}

void playExpandableSheetSnapHaptic({
  required bool wasExpanded,
  required bool isExpanded,
}) {
  if (wasExpanded == isExpanded) {
    return;
  }
  if (isExpanded) {
    unawaited(HapticFeedback.mediumImpact());
    return;
  }
  unawaited(HapticFeedback.lightImpact());
}

void playExpandableSheetDismissHaptic() {
  unawaited(HapticFeedback.lightImpact());
}

bool expandableSheetIsPastCollapsedHeight({
  required double currentHeight,
  required double collapsedHeight,
}) {
  return currentHeight > collapsedHeight + 1;
}

bool? updateExpandableSheetDragHaptic({
  required bool? wasPastCollapsed,
  required double previousHeight,
  required double currentHeight,
  required double collapsedHeight,
}) {
  final bool wasPast =
      wasPastCollapsed ??
      expandableSheetIsPastCollapsedHeight(
        currentHeight: previousHeight,
        collapsedHeight: collapsedHeight,
      );
  final bool isPastCollapsed = expandableSheetIsPastCollapsedHeight(
    currentHeight: currentHeight,
    collapsedHeight: collapsedHeight,
  );
  if (wasPast != isPastCollapsed) {
    playExpandableSheetSnapHaptic(
      wasExpanded: wasPast,
      isExpanded: isPastCollapsed,
    );
  }
  return isPastCollapsed;
}

class ExpandableSheetDragTarget extends StatelessWidget {
  const ExpandableSheetDragTarget({
    required this.onVerticalDragUpdate,
    required this.onVerticalDragEnd,
    required this.child,
    super.key,
  });

  final GestureDragUpdateCallback onVerticalDragUpdate;
  final GestureDragEndCallback onVerticalDragEnd;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: onVerticalDragUpdate,
      onVerticalDragEnd: onVerticalDragEnd,
      child: child,
    );
  }
}
