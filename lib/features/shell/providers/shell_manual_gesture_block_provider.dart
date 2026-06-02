import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shell_manual_gesture_block_provider.g.dart';

// Set while UI blocks shell gestures without a Navigator popup route
// (voice message recording overlay, etc.).
@Riverpod(keepAlive: true)
class ShellManualGestureBlock extends _$ShellManualGestureBlock {
  @override
  bool build() => false;

  void setBlocked({required bool value}) {
    if (state == value) {
      return;
    }
    state = value;
  }
}
