import 'dart:ui';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'guild_drag_provider.g.dart';

const double kGuildDragCollapseThreshold = 12;

enum DropPosition { before, after, combine }

class DragState {
  const DragState({
    this.dragItemId,
    this.hoverTargetId,
    this.hoverTargetIsFolder = false,
    this.dropPosition,
    this.hasMovedFromHoldPoint = false,
  });

  final String? dragItemId;
  final String? hoverTargetId;
  final bool hoverTargetIsFolder;
  final DropPosition? dropPosition;
  final bool hasMovedFromHoldPoint;

  bool get isDragging => dragItemId != null;
  bool get hasHoverTarget => hoverTargetId != null;

  DragState copyWith({
    String? dragItemId,
    String? hoverTargetId,
    bool? hoverTargetIsFolder,
    DropPosition? dropPosition,
    bool? hasMovedFromHoldPoint,
    bool clearDragItemId = false,
    bool clearHoverTargetId = false,
    bool clearDropPosition = false,
  }) {
    return DragState(
      dragItemId: clearDragItemId ? null : (dragItemId ?? this.dragItemId),
      hoverTargetId: clearHoverTargetId
          ? null
          : (hoverTargetId ?? this.hoverTargetId),
      hoverTargetIsFolder: hoverTargetIsFolder ?? this.hoverTargetIsFolder,
      dropPosition: clearDropPosition
          ? null
          : (dropPosition ?? this.dropPosition),
      hasMovedFromHoldPoint:
          hasMovedFromHoldPoint ?? this.hasMovedFromHoldPoint,
    );
  }
}

@Riverpod(keepAlive: true)
class GuildDrag extends _$GuildDrag {
  Offset? _dragStartGlobalPosition;

  @override
  DragState build() => const DragState();

  void startDrag(String itemId) {
    _dragStartGlobalPosition = null;
    state = DragState(dragItemId: itemId);
  }

  void updateDragMovement(Offset globalPosition) {
    _dragStartGlobalPosition ??= globalPosition;
    if (state.hasMovedFromHoldPoint) {
      return;
    }
    final double verticalDistance =
        (globalPosition.dy - _dragStartGlobalPosition!.dy).abs();
    if (verticalDistance >= kGuildDragCollapseThreshold) {
      state = state.copyWith(hasMovedFromHoldPoint: true);
    }
  }

  bool updateHover({
    required String targetId,
    required bool isFolder,
    required DropPosition position,
  }) {
    final bool didChangeTarget = state.hoverTargetId != targetId;
    final bool didChangePosition = state.dropPosition != position;
    if (!didChangeTarget &&
        !didChangePosition &&
        state.hoverTargetIsFolder == isFolder) {
      return false;
    }
    state = state.copyWith(
      hoverTargetId: targetId,
      hoverTargetIsFolder: isFolder,
      dropPosition: position,
    );
    return didChangeTarget;
  }

  void clearHover() {
    state = state.copyWith(
      clearHoverTargetId: true,
      hoverTargetIsFolder: false,
      clearDropPosition: true,
    );
  }

  void endDrag() {
    _dragStartGlobalPosition = null;
    state = const DragState();
  }
}
