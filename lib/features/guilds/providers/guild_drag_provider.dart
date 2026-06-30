import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'guild_drag_provider.g.dart';

enum DropPosition { before, after, combine }

class DragState {
  const DragState({
    this.dragItemId,
    this.hoverTargetId,
    this.hoverTargetIsFolder = false,
    this.dropPosition,
  });

  final String? dragItemId;
  final String? hoverTargetId;
  final bool hoverTargetIsFolder;
  final DropPosition? dropPosition;

  bool get isDragging => dragItemId != null;
  bool get hasHoverTarget => hoverTargetId != null;

  DragState copyWith({
    String? dragItemId,
    String? hoverTargetId,
    bool? hoverTargetIsFolder,
    DropPosition? dropPosition,
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
    );
  }
}

@Riverpod(keepAlive: true)
class GuildDrag extends _$GuildDrag {
  @override
  DragState build() => const DragState();

  void startDrag(String itemId) {
    state = DragState(dragItemId: itemId);
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
    state = const DragState();
  }
}
