import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/moderation/iar/iar_flow.dart';
import 'package:fluxer_dart/export.dart';

void main() {
  group('ruleReasonsByCategory', () {
    test('every reason belongs to exactly one category', () {
      final seen = <IarRuleReason>{};
      for (final reasons in ruleReasonsByCategory.values) {
        for (final reason in reasons) {
          expect(
            seen.add(reason),
            isTrue,
            reason: '$reason is in more than one category',
          );
        }
      }
    });

    test('every reason is reachable from some category', () {
      final reachable = <IarRuleReason>{
        for (final reasons in ruleReasonsByCategory.values) ...reasons,
      };
      expect(reachable, equals(IarRuleReason.values.toSet()));
    });
  });

  group('iarCategoryForReason', () {
    test('inverse of ruleReasonsByCategory for every reason', () {
      for (final reason in IarRuleReason.values) {
        final category = iarCategoryForReason(reason);
        expect(
          ruleReasonsByCategory[category],
          contains(reason),
          reason: '$reason should map back into category $category',
        );
      }
    });
  });

  group('iarReasonToMessageCategory', () {
    test('every IAR reason maps to a defined backend enum value', () {
      for (final reason in IarRuleReason.values) {
        final wire = iarReasonToMessageCategory(reason);
        expect(
          wire,
          isNot(equals(MessageReportCategoryEnum.$unknown)),
          reason: '$reason maps to \$unknown',
        );
      }
    });

    test('rule reasons that share a wire category match the web mapping', () {
      // harassment and raidCoordination both route to harassment wire-side
      // (`REPORT_CATEGORY_BY_REASON.{harassment,raid_coordination}.message`
      // on the web).
      expect(
        iarReasonToMessageCategory(IarRuleReason.harassment),
        equals(MessageReportCategoryEnum.harassment),
      );
      expect(
        iarReasonToMessageCategory(IarRuleReason.raidCoordination),
        equals(MessageReportCategoryEnum.harassment),
      );
      // terrorismExtremism shares violentContent with violence.
      expect(
        iarReasonToMessageCategory(IarRuleReason.terrorismExtremism),
        equals(MessageReportCategoryEnum.violentContent),
      );
      expect(
        iarReasonToMessageCategory(IarRuleReason.violence),
        equals(MessageReportCategoryEnum.violentContent),
      );
      // Reasons that exist only for non-message contexts on the web
      // (`inappropriateProfile`, `harmfulMisinformation`) fall through to
      // the catch-all `other` wire value for messages.
      expect(
        iarReasonToMessageCategory(IarRuleReason.inappropriateProfile),
        equals(MessageReportCategoryEnum.other),
      );
      expect(
        iarReasonToMessageCategory(IarRuleReason.harmfulMisinformation),
        equals(MessageReportCategoryEnum.other),
      );
    });
  });
}
