import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/ui/bottom_sheet/fluxer_bottom_sheet.dart';

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
  group('FluxerBottomSheet', () {
    testWidgets('shows bottom sheet with title', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  FluxerBottomSheet.show(
                    context,
                    title: 'Test Title',
                    builder: (context, close) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Sheet Content'),
                      );
                    },
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Sheet Content'), findsOneWidget);
    });

    testWidgets('builder receives working close callback', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  FluxerBottomSheet.show(
                    context,
                    title: 'Closeable Sheet',
                    builder: (context, close) {
                      return ElevatedButton(
                        onPressed: close,
                        child: const Text('Close Me'),
                      );
                    },
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Closeable Sheet'), findsOneWidget);

      await tester.tap(find.text('Close Me'));
      await tester.pumpAndSettle();

      expect(find.text('Closeable Sheet'), findsNothing);
    });

    testWidgets('shows drag handle', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  FluxerBottomSheet.show(
                    context,
                    builder: (context, close) {
                      return const SizedBox(height: 100);
                    },
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(FluxerBottomSheetDragHandle), findsOneWidget);
    });
  });
}
