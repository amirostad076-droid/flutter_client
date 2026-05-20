import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/router/shell_popup_route_observer.dart';

void main() {
  group('ShellPopupRouteObserver', () {
    test('tracks popup routes across push and pop', () {
      final List<bool> states = <bool>[];
      final ShellPopupRouteObserver observer = ShellPopupRouteObserver(
        ({required bool hasOverlay}) => states.add(hasOverlay),
      );
      final Route<void> pageRoute = _FakePageRoute<void>();
      final Route<void> popupRoute = _FakePopupRoute<void>();

      observer.didPush(pageRoute, null);
      expect(states, isEmpty);

      observer.didPush(popupRoute, pageRoute);
      expect(states, <bool>[true]);

      observer.didPop(popupRoute, pageRoute);
      expect(states, <bool>[true, false]);
    });

    test('remove decrements popup tracking', () {
      final List<bool> states = <bool>[];
      final ShellPopupRouteObserver observer = ShellPopupRouteObserver(
        ({required bool hasOverlay}) => states.add(hasOverlay),
      );
      final Route<void> popupRoute = _FakePopupRoute<void>();

      observer.didPush(popupRoute, null);
      observer.didRemove(popupRoute, null);
      expect(states, <bool>[true, false]);
    });

    test('replace swaps popup tracking', () {
      final List<bool> states = <bool>[];
      final ShellPopupRouteObserver observer = ShellPopupRouteObserver(
        ({required bool hasOverlay}) => states.add(hasOverlay),
      );
      final Route<void> oldPopup = _FakePopupRoute<void>();
      final Route<void> newPopup = _FakePopupRoute<void>();

      observer.didPush(oldPopup, null);
      expect(states, <bool>[true]);

      observer.didReplace(newRoute: newPopup, oldRoute: oldPopup);
      expect(states, <bool>[true, false, true]);
    });
  });
}

class _FakePageRoute<T> extends Route<T> {
  @override
  bool get opaque => true;

  @override
  bool get barrierDismissible => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => const SizedBox.shrink();

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

class _FakePopupRoute<T> extends PopupRoute<T> {
  @override
  Color? get barrierColor => Colors.black54;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => const SizedBox.shrink();
}
