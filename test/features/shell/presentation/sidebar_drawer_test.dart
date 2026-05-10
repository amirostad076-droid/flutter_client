import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/features/shell/presentation/sidebar_drawer.dart';
import 'package:fluxer_app/features/shell/providers/reveal_side_provider.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('sidebarDrawerTargetForDrag', () {
    test('uses fling velocity before position threshold', () {
      expect(
        sidebarDrawerTargetForDrag(
          translate: 0,
          width: 400,
          primaryVelocity: 700,
          completionThreshold: 0.4,
        ),
        RevealSide.left,
      );
      expect(
        sidebarDrawerTargetForDrag(
          translate: 400,
          width: 400,
          primaryVelocity: -700,
          completionThreshold: 0.4,
        ),
        RevealSide.main,
      );
    });

    test('falls back to position threshold without a fling', () {
      expect(
        sidebarDrawerTargetForDrag(
          translate: 159,
          width: 400,
          primaryVelocity: 0,
          completionThreshold: 0.4,
        ),
        RevealSide.main,
      );
      expect(
        sidebarDrawerTargetForDrag(
          translate: 160,
          width: 400,
          primaryVelocity: 0,
          completionThreshold: 0.4,
        ),
        RevealSide.left,
      );
    });
  });

  testWidgets('tracks opening drags from anywhere on the surface', (
    tester,
  ) async {
    final router = _routerFor('/channels/guild/channel');
    addTearDown(router.dispose);
    final container = _containerFor(router);

    await tester.pumpWidget(_buildDrawerApp(container: container));

    // Mid-screen — not a leading edge strip — must still capture the drag.
    final gesture = await tester.startGesture(const Offset(200, 400));
    await gesture.moveBy(const Offset(80, 0));
    await tester.pump();

    expect(_sliderDx(tester), 80);

    await gesture.moveBy(const Offset(180, 0));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(_sliderDx(tester), 400);
  });

  testWidgets('allows closing with a swipe from anywhere when open', (
    tester,
  ) async {
    final router = _routerFor('/channels/guild/channel');
    addTearDown(router.dispose);
    final container = _containerFor(router);

    await tester.pumpWidget(_buildDrawerApp(container: container));
    await tester.pump();

    await tester.dragFrom(const Offset(10, 400), const Offset(260, 0));
    await tester.pumpAndSettle();

    expect(_sliderDx(tester), 400);

    // Closing drag starts mid-screen, not at the edge.
    await tester.dragFrom(const Offset(240, 400), const Offset(-260, 0));
    await tester.pumpAndSettle();

    expect(_sliderDx(tester), 0);
  });

  testWidgets('keeps open progress when width changes', (tester) async {
    final router = _routerFor('/channels/guild/channel');
    addTearDown(router.dispose);
    final container = _containerFor(router);

    await tester.pumpWidget(_buildDrawerApp(container: container));
    await tester.pump();
    await tester.dragFrom(const Offset(10, 400), const Offset(260, 0));
    await tester.pumpAndSettle();

    expect(_sliderDx(tester), 400);

    await tester.pumpWidget(
      _buildDrawerApp(container: container, size: const Size(800, 800)),
    );
    await tester.pump();

    expect(_sliderDx(tester), 800);
  });

  testWidgets('wraps drawer layers in repaint boundaries', (tester) async {
    final router = _routerFor('/channels/guild/channel');
    addTearDown(router.dispose);
    final container = _containerFor(router);

    await tester.pumpWidget(_buildDrawerApp(container: container));

    expect(find.byType(RepaintBoundary), findsAtLeastNWidgets(2));
  });
}

const _sliderKey = ValueKey<String>('slider');

GoRouter _routerFor(String initialLocation) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/channels/:guildId/:channelId',
        builder: (context, state) => const SizedBox.shrink(),
      ),
    ],
  );
}

ProviderContainer _containerFor(GoRouter router) {
  final container = ProviderContainer(
    overrides: [fluxerRouterProvider.overrideWithValue(router)],
  );
  addTearDown(container.dispose);
  return container;
}

Widget _buildDrawerApp({
  required ProviderContainer container,
  Size size = const Size(400, 800),
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: const SidebarDrawer(
            revealDuration: Duration.zero,
            snapBackDuration: Duration.zero,
            base: ColoredBox(color: Colors.blue),
            slider: ColoredBox(key: _sliderKey, color: Colors.red),
          ),
        ),
      ),
    ),
  );
}

double _sliderDx(WidgetTester tester) {
  final transform = tester.widget<Transform>(
    find.ancestor(of: find.byKey(_sliderKey), matching: find.byType(Transform)),
  );
  return transform.transform.getTranslation().x;
}
