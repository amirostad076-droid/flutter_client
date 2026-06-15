import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'voice_call_layout_provider.g.dart';

enum VoiceCallLayoutMode {
  /// All tiles share a responsive grid
  grid,

  /// One large tile with the rest in a film mode
  focus,
}

class VoiceCallLayoutState {
  const VoiceCallLayoutState({
    this.mode = VoiceCallLayoutMode.grid,
    this.pinnedTileId,
  });

  final VoiceCallLayoutMode mode;
  final String? pinnedTileId;

  bool isPinned(String tileId) => pinnedTileId == tileId;
}

/// Grid vs focus layout for the active voice call
@Riverpod(keepAlive: true)
class VoiceCallLayout extends _$VoiceCallLayout {
  @override
  VoiceCallLayoutState build() => const VoiceCallLayoutState();

  void pin(String tileId) {
    state = VoiceCallLayoutState(
      mode: VoiceCallLayoutMode.focus,
      pinnedTileId: tileId,
    );
  }

  void unpin() {
    if (state.pinnedTileId == null && state.mode == VoiceCallLayoutMode.grid) {
      return;
    }
    state = const VoiceCallLayoutState();
  }

  void togglePin(String tileId) {
    if (state.pinnedTileId == tileId) {
      unpin();
    } else {
      pin(tileId);
    }
  }

  void reset() {
    if (state.pinnedTileId == null && state.mode == VoiceCallLayoutMode.grid) {
      return;
    }
    state = const VoiceCallLayoutState();
  }
}
