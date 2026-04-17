import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/profile/presentation/widgets/user_profile_badges.dart';

void main() {
  group('UserProfileBadges', () {
    testWidgets('renders nothing for zero flags', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: UserProfileBadges(flags: 0)),
      );
      expect(find.byType(SvgPicture), findsNothing);
    });

    testWidgets('renders Staff badge for flag bit 0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: UserProfileBadges(flags: 1)),
      );
      expect(find.byType(SvgPicture), findsOneWidget);
    });

    testWidgets('renders three badges for staff+partner+bug-hunter', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: UserProfileBadges(flags: 1 | 4 | 8)),
      );
      expect(find.byType(SvgPicture), findsNWidgets(3));
    });
  });
}
