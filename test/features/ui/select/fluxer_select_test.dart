import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxeron/core/theme/fluxer_layout_theme.dart';
import 'package:fluxeron/core/theme/fluxer_text_theme.dart';
import 'package:fluxeron/core/theme/fluxer_theme.dart';
import 'package:fluxeron/core/theme/themes/dark.dart';
import 'package:fluxeron/features/ui/select/fluxer_select.dart';
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
  final items = [
    const FluxerSelectItem(value: 'a', label: 'Alpha'),
    const FluxerSelectItem(value: 'b', label: 'Beta'),
    const FluxerSelectItem(value: 'c', label: 'Gamma'),
  ];

  group('FluxerSelect', () {
    testWidgets('renders selected item label', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          FluxerSelect<String>(items: items, value: 'b', onChanged: (_) {}),
        ),
      );

      expect(find.text('Beta'), findsOneWidget);
    });

    testWidgets('renders hint when no value is selected', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          FluxerSelect<String>(
            items: items,
            hint: 'Pick one',
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text('Pick one'), findsOneWidget);
    });

    testWidgets('shows dropdown items when tapped', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          FluxerSelect<String>(items: items, value: 'a', onChanged: (_) {}),
        ),
      );

      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();

      // All items should be visible in the dropdown
      expect(find.text('Alpha'), findsExactly(2));
      expect(find.text('Beta'), findsOneWidget);
      expect(find.text('Gamma'), findsOneWidget);
    });

    testWidgets('calls onChanged and closes popout on item tap', (
      tester,
    ) async {
      String? selectedValue;
      await tester.pumpWidget(
        buildTestApp(
          FluxerSelect<String>(
            items: items,
            onChanged: (value) => selectedValue = value,
          ),
        ),
      );

      // Open the dropdown by tapping the caret icon area
      await tester.tap(find.byIcon(PhosphorIconsBold.caretDown));
      await tester.pumpAndSettle();

      // Tap on Beta
      await tester.tap(find.text('Beta'));
      await tester.pumpAndSettle();

      expect(selectedValue, equals('b'));
      // Dropdown should be closed — only the trigger text remains
      expect(find.text('Gamma'), findsNothing);
    });

    testWidgets('renders label above the trigger', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          FluxerSelect<String>(
            items: items,
            label: 'Choose option',
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text('Choose option'), findsOneWidget);
    });

    testWidgets('shows check icon for selected item in dropdown', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          FluxerSelect<String>(items: items, value: 'a', onChanged: (_) {}),
        ),
      );

      // No check icon visible before opening
      expect(find.byIcon(PhosphorIconsBold.check), findsNothing);

      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();

      // Check icon visible for selected item
      expect(find.byIcon(PhosphorIconsBold.check), findsOneWidget);
    });
  });
}
