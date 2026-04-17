import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/ui/button/fluxer_button.dart';
import 'package:fluxer_app/features/ui/button/fluxer_button_size.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

Widget buildTestApp(Widget child) {
  final colorTheme = buildDarkColorTheme();
  return MaterialApp(
    theme: buildFluxerTheme(
      colorTheme: colorTheme,
      textTheme: FluxerTextTheme.fromColors(colorTheme),
      layoutTheme: FluxerLayoutTheme.scaled(),
    ),
    home: Scaffold(body: child),
  );
}

void main() {
  group('FluxerButton', () {
    testWidgets('primary variant renders label text', (tester) async {
      await tester.pumpWidget(
        buildTestApp(FluxerButton.primary(onPressed: () {}, label: 'Click me')),
      );

      expect(find.text('Click me'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildTestApp(
          FluxerButton.primary(onPressed: () => tapped = true, label: 'Tap'),
        ),
      );

      await tester.tap(find.text('Tap'));
      expect(tapped, isTrue);
    });

    testWidgets('does NOT call onPressed when loading', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildTestApp(
          FluxerButton.primary(
            onPressed: () => tapped = true,
            label: 'Loading',
            isLoading: true,
          ),
        ),
      );

      await tester.tap(find.byType(FluxerButton));
      expect(tapped, isFalse);
    });

    testWidgets('shows CircularProgressIndicator when loading', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          FluxerButton.primary(
            onPressed: () {},
            label: 'Loading',
            isLoading: true,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading'), findsNothing);
    });

    testWidgets('all 7 named constructors create a widget', (tester) async {
      final constructors = <Widget>[
        FluxerButton.primary(onPressed: () {}, label: 'primary'),
        FluxerButton.secondary(onPressed: () {}, label: 'secondary'),
        FluxerButton.dangerPrimary(onPressed: () {}, label: 'dangerPrimary'),
        FluxerButton.dangerSecondary(
          onPressed: () {},
          label: 'dangerSecondary',
        ),
        FluxerButton.inverted(onPressed: () {}, label: 'inverted'),
        FluxerButton.invertedOutline(
          onPressed: () {},
          label: 'invertedOutline',
        ),
        FluxerButton.ghost(onPressed: () {}, label: 'ghost'),
      ];

      for (final button in constructors) {
        await tester.pumpWidget(buildTestApp(button));
        expect(find.byType(FluxerButton), findsOneWidget);
      }
    });

    testWidgets('compact size renders with height 32', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          FluxerButton.primary(
            onPressed: () {},
            label: 'Compact',
            size: FluxerButtonSize.compact,
          ),
        ),
      );

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final constraints = container.constraints!;
      expect(constraints.minHeight, 32);
    });

    testWidgets('renders icon when provided', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          FluxerButton.primary(
            onPressed: () {},
            label: 'With icon',
            icon: PhosphorIconsBold.check,
          ),
        ),
      );

      expect(find.byType(PhosphorIcon), findsOneWidget);
      expect(find.text('With icon'), findsOneWidget);
    });

    testWidgets('renders as square icon-only button', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          FluxerButton.primary(
            onPressed: () {},
            icon: PhosphorIconsBold.plus,
            isSquare: true,
          ),
        ),
      );

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final constraints = container.constraints!;
      expect(constraints.minWidth, constraints.minHeight);
    });

    testWidgets('does not call onPressed when onPressed is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          const FluxerButton.primary(label: 'Disabled'),
        ),
      );

      await tester.tap(find.byType(FluxerButton));
      // No exception means the tap was safely ignored.
    });
  });
}
