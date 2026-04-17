import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/profile/presentation/widgets/user_profile_custom_status.dart';

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
  group('UserProfileCustomStatus', () {
    testWidgets('renders nothing for null', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const UserProfileCustomStatus(text: null)),
      );
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('renders nothing for empty', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const UserProfileCustomStatus(text: '')),
      );
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('renders text when set', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const UserProfileCustomStatus(text: 'Coding')),
      );
      expect(find.text('Coding'), findsOneWidget);
    });
  });
}
