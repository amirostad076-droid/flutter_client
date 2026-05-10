import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/profile/presentation/widgets/user_profile_badges.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';

Widget _buildApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: FluxerLocalizations.localizationsDelegates,
    supportedLocales: FluxerLocalizations.supportedLocales,
    home: child,
  );
}

void main() {
  group('UserProfileBadges', () {
    testWidgets('renders nothing for zero flags', (tester) async {
      await tester.pumpWidget(_buildApp(const UserProfileBadges(flags: 0)));
      expect(find.byType(SvgPicture), findsNothing);
    });

    testWidgets('renders Staff badge for flag bit 0', (tester) async {
      await tester.pumpWidget(_buildApp(const UserProfileBadges(flags: 1)));
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.byTooltip('Fluxer Staff'), findsOneWidget);
    });

    testWidgets('renders CTP badge for flag bit 1', (tester) async {
      await tester.pumpWidget(_buildApp(const UserProfileBadges(flags: 2)));
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.byTooltip('Fluxer Community Team'), findsOneWidget);
    });

    testWidgets('renders four badges for staff+ctp+partner+bug-hunter', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(const UserProfileBadges(flags: 1 | 2 | 4 | 8)),
      );
      expect(find.byType(SvgPicture), findsNWidgets(4));
      expect(find.byTooltip('Fluxer Partner'), findsOneWidget);
      expect(find.byTooltip('Fluxer Bug Hunter'), findsOneWidget);
    });

    testWidgets('renders Plutonium badge when user has Plutonium', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(const UserProfileBadges(flags: 0, hasPlutonium: true)),
      );
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.byTooltip('Fluxer Plutonium'), findsOneWidget);
    });
  });
}
