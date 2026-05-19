import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/limits/limit_context.dart';
import 'package:fluxer_app/core/limits/limit_defaults.dart';
import 'package:fluxer_app/core/limits/limit_evaluator.dart';
import 'package:fluxer_app/core/limits/limit_key.dart';
import 'package:fluxer_app/core/limits/limit_types.dart';
import 'package:fluxer_app/features/chat/utils/file_upload_constants.dart';

void main() {
  group('LimitEvaluator', () {
    test('applies premium attachment limit when premium trait matches', () {
      const LimitConfigSnapshot snapshot = LimitConfigSnapshot(
        traitDefinitions: <String>['premium'],
        rules: <LimitRule>[
          LimitRule(
            id: 'premium',
            filters: LimitFilter(traits: <String>['premium']),
            limits: <String, int>{
              LimitKeys.maxAttachmentFileSize: kPremiumMaxAttachmentBytes,
            },
          ),
        ],
      );
      final LimitEvaluator evaluator = LimitEvaluator(snapshot);
      final int actual = evaluator.resolveOne(
        buildUserLimitContext(isPremium: true),
        LimitKeys.maxAttachmentFileSize,
      );
      expect(actual, kPremiumMaxAttachmentBytes);
    });

    test('uses free defaults when premium trait does not match', () {
      const LimitConfigSnapshot snapshot = LimitConfigSnapshot(
        traitDefinitions: <String>['premium'],
        rules: <LimitRule>[
          LimitRule(
            id: 'premium',
            filters: LimitFilter(traits: <String>['premium']),
            limits: <String, int>{
              LimitKeys.maxAttachmentFileSize: kPremiumMaxAttachmentBytes,
            },
          ),
        ],
      );
      final LimitEvaluator evaluator = LimitEvaluator(snapshot);
      final int actual = evaluator.resolveOne(
        buildUserLimitContext(isPremium: false),
        LimitKeys.maxAttachmentFileSize,
      );
      expect(actual, kDefaultFreeLimits[LimitKeys.maxAttachmentFileSize]);
    });
  });
}
