import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/router/shell_navigator_keys.dart';
import 'package:fluxer_app/core/router/shell_popup_route_observer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShellPopupRouteObserver', () {
    testWidgets('tracks popup routes across push and pop', (tester) async {
      final List<bool> states = <bool>[];
      final ShellPopupRouteObserver observer = ShellPopupRouteObserver(
        ({required bool hasOverlay}) => states.add(hasOverlay),
      );
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: homeBranchNavigatorKey,
          navigatorObservers: <NavigatorObserver>[observer],
          home: const SizedBox.shrink(),
        ),
      );

      homeBranchNavigatorKey.currentState!.push(_FakePopupRoute<void>());
      await tester.pumpAndSettle();
      expect(states, contains(true));

      homeBranchNavigatorKey.currentState!.pop();
      await tester.pumpAndSettle();
      expect(states.last, isFalse);
    });

    testWidgets('remove decrements popup tracking', (tester) async {
      final List<bool> states = <bool>[];
      final ShellPopupRouteObserver observer = ShellPopupRouteObserver(
        ({required bool hasOverlay}) => states.add(hasOverlay),
      );
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: homeBranchNavigatorKey,
          navigatorObservers: <NavigatorObserver>[observer],
          home: const SizedBox.shrink(),
        ),
      );

      final Route<void> popupRoute = _FakePopupRoute<void>();
      homeBranchNavigatorKey.currentState!.push(popupRoute);
      await tester.pumpAndSettle();
      expect(states, contains(true));

      homeBranchNavigatorKey.currentState!.removeRoute(popupRoute);
      await tester.pumpAndSettle();
      expect(states.last, isFalse);
    });

    testWidgets('replace keeps popup tracking when swapping popups', (
      tester,
    ) async {
      final List<bool> states = <bool>[];
      final ShellPopupRouteObserver observer = ShellPopupRouteObserver(
        ({required bool hasOverlay}) => states.add(hasOverlay),
      );
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: homeBranchNavigatorKey,
          navigatorObservers: <NavigatorObserver>[observer],
          home: const SizedBox.shrink(),
        ),
      );

      final NavigatorState navigator = homeBranchNavigatorKey.currentState!;
      navigator.push(_FakePopupRoute<void>());
      await tester.pumpAndSettle();
      expect(states, contains(true));

      navigator.pushReplacement(_FakePopupRoute<void>());
      await tester.pumpAndSettle();
      expect(states.last, isTrue);
    });
  });
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
