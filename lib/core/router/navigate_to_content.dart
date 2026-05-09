import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/features/shell/providers/reveal_side_provider.dart';
import 'package:go_router/go_router.dart';

final _chatRoutePattern = RegExp('^/channels/[^/]+/.+');

/// Navigates to [path] using go() which declaratively updates the route stack.
///
/// Using go() ensures the [StatefulShellRoute] builder receives the updated
/// location. Child routes maintain the parent in the stack, so pop() and
/// system back gestures still work on mobile.
///
/// When [path] targets a chat route, the mobile sidebar drawer is forced to
/// the main side before navigating. This guarantees the drawer closes even
/// when the user re-taps the channel they are already viewing — go() is a
/// no-op for an unchanged location, so the route-change listener never fires.
void navigateToContent(BuildContext context, String path) {
  if (_chatRoutePattern.hasMatch(path)) {
    ProviderScope.containerOf(context)
        .read(currentRevealSideProvider.notifier)
        .set(RevealSide.main);
  }
  context.go(path);
}
