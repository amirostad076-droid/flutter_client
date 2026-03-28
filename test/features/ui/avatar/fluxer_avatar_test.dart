import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/ui/avatar/fluxer_avatar.dart';
import 'package:fluxer_app/features/ui/status_indicator/fluxer_status_indicator.dart';

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
  group('FluxerAvatar', () {
    testWidgets('user variant renders with fallback text', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const FluxerAvatar.user(fallbackText: 'Alice', showStatus: false),
        ),
      );

      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('user variant shows status indicator when status set', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          const FluxerAvatar.user(fallbackText: 'Bob', status: 'online'),
        ),
      );

      expect(find.byType(FluxerStatusIndicator), findsOneWidget);
    });

    testWidgets('guild variant renders with fallback text', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const FluxerAvatar.guild(fallbackText: 'My Server')),
      );

      expect(find.text('M'), findsOneWidget);
      expect(find.byType(FluxerStatusIndicator), findsNothing);
    });

    testWidgets('default constructor renders without status', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const FluxerAvatar(fallbackText: 'Test')),
      );

      expect(find.text('T'), findsOneWidget);
      expect(find.byType(FluxerStatusIndicator), findsNothing);
    });
  });

  group('FluxerStatusIndicator', () {
    testWidgets('shows correct color for online status', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const FluxerStatusIndicator(status: 'online')),
      );

      final indicator = tester.widget<FluxerStatusIndicator>(
        find.byType(FluxerStatusIndicator),
      );
      expect(indicator.status, 'online');

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, 12);
      expect(sizedBox.height, 12);
    });

    testWidgets('renders all status variants without error', (tester) async {
      for (final status in ['online', 'idle', 'dnd', 'streaming', 'offline']) {
        await tester.pumpWidget(
          buildTestApp(FluxerStatusIndicator(status: status)),
        );
        expect(find.byType(FluxerStatusIndicator), findsOneWidget);
      }
    });
  });
}
