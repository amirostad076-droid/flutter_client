import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reveal_side_provider.g.dart';

enum RevealSide { left, main }

final _rootRoutePattern = RegExp(r'^/channels/[^/]+$');

@Riverpod(keepAlive: true)
class CurrentRevealSide extends _$CurrentRevealSide {
  @override
  RevealSide build() {
    final router = ref.read(fluxerRouterProvider);
    return _sideForRoute(router);
  }

  // Riverpod notifiers in this app use method-style mutations at call sites.
  // ignore: use_setters_to_change_properties
  void set(RevealSide side) {
    state = side;
  }

  static RevealSide _sideForRoute(GoRouter router) {
    final config = router.routerDelegate.currentConfiguration;
    if (config.isEmpty) {
      return RevealSide.main;
    }
    final pathLocation = config.last.matchedLocation;
    if (_rootRoutePattern.hasMatch(pathLocation)) {
      return RevealSide.left;
    }
    return RevealSide.main;
  }
}
