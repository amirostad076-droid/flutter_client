import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/features/shell/providers/reveal_side_provider.dart';

/// Navigates to [path] using `go()` and pre-sets the mobile drawer for
/// chat-route targets so re-tapping the active channel still closes the
/// drawer (`context.go` is a no-op when the location is unchanged, so the
/// post-nav route listener never fires).
///
/// Use this from widgets. For non-context call sites (notifiers,
/// providers, deep-link handlers) use [navigateToContentVia].
void navigateToContent(BuildContext context, String path) {
  final container = ProviderScope.containerOf(context);
  final eager = eagerRevealSideFor(path);
  if (eager != null) {
    container.read(currentRevealSideProvider.notifier).set(eager);
  }
  container.read(fluxerRouterProvider).go(path);
}

/// Same as [navigateToContent] but for call sites that hold a Riverpod
/// [Ref] instead of a [BuildContext] (e.g. notifiers, deep-link handlers,
/// non-widget providers).
void navigateToContentVia(Ref ref, String path) {
  final eager = eagerRevealSideFor(path);
  if (eager != null) {
    ref.read(currentRevealSideProvider.notifier).set(eager);
  }
  ref.read(fluxerRouterProvider).go(path);
}
