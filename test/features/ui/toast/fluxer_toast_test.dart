import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxeron/core/theme/fluxer_layout_theme.dart';
import 'package:fluxeron/core/theme/fluxer_text_theme.dart';
import 'package:fluxeron/core/theme/fluxer_theme.dart';
import 'package:fluxeron/core/theme/themes/dark.dart';
import 'package:fluxeron/features/ui/toast/fluxer_toast.dart';
import 'package:fluxeron/features/ui/toast/fluxer_toast_overlay.dart';
import 'package:fluxeron/features/ui/toast/toast_provider.dart';

Widget buildTestApp(Widget child) {
  final colorTheme = buildDarkColorTheme();
  return ProviderScope(
    child: MaterialApp(
      theme: buildFluxerTheme(
        colorTheme: colorTheme,
        textTheme: FluxerTextTheme.fromColors(colorTheme),
        layoutTheme: FluxerLayoutTheme.scaled(),
      ),
      home: Scaffold(body: FluxerToastOverlay(child: child)),
    ),
  );
}

void main() {
  group('FluxerToastOverlay', () {
    testWidgets('shows toast message when triggered via provider', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp(const SizedBox.shrink()));

      final container = ProviderScope.containerOf(
        tester.element(find.byType(FluxerToastOverlay)),
      );
      container
          .read(toastProvider.notifier)
          .show(const FluxerToast(message: 'Test notification'));

      await tester.pump();

      expect(find.text('Test notification'), findsOneWidget);

      // Advance past toast duration to clear pending timer.
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();
    });

    testWidgets('toast is dismissible via swipe', (tester) async {
      await tester.pumpWidget(buildTestApp(const SizedBox.shrink()));

      final container = ProviderScope.containerOf(
        tester.element(find.byType(FluxerToastOverlay)),
      );
      container
          .read(toastProvider.notifier)
          .show(const FluxerToast(message: 'Swipe me away'));

      await tester.pump();
      expect(find.text('Swipe me away'), findsOneWidget);

      await tester.drag(find.byType(Dismissible), const Offset(500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Swipe me away'), findsNothing);

      // Advance past toast duration to clear pending timer.
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();
    });

    testWidgets('shows action button when action is provided', (tester) async {
      var actionPressed = false;
      await tester.pumpWidget(buildTestApp(const SizedBox.shrink()));

      final container = ProviderScope.containerOf(
        tester.element(find.byType(FluxerToastOverlay)),
      );
      container
          .read(toastProvider.notifier)
          .show(
            FluxerToast(
              message: 'With action',
              action: FluxerToastAction(
                label: 'Undo',
                onPressed: () => actionPressed = true,
              ),
            ),
          );

      await tester.pump();

      expect(find.text('Undo'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      expect(actionPressed, isTrue);

      // Advance past toast duration to clear pending timer.
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();
    });

    testWidgets('auto-dismisses after duration', (tester) async {
      await tester.pumpWidget(buildTestApp(const SizedBox.shrink()));

      final container = ProviderScope.containerOf(
        tester.element(find.byType(FluxerToastOverlay)),
      );
      container
          .read(toastProvider.notifier)
          .show(
            const FluxerToast(
              message: 'Temporary',
              duration: Duration(seconds: 2),
            ),
          );

      await tester.pump();
      expect(find.text('Temporary'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      await tester.pump();

      expect(find.text('Temporary'), findsNothing);
    });
  });
}
