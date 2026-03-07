import 'package:fluxeron/shared/widgets/responsive_layout.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'layout_mode_provider.g.dart';

/// Current layout mode (mobile / tablet / desktop) for router and shell.
/// Updated by a sync widget when the app is laid out so redirect and shell
/// react to window resize.
@Riverpod(keepAlive: true)
class LayoutModeNotifier extends _$LayoutModeNotifier {
  @override
  LayoutMode build() => LayoutMode.desktop;

  void setMode(LayoutMode mode) {
    if (state != mode) {
      state = mode;
    }
  }
}
