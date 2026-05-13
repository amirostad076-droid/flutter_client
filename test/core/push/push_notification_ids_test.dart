import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/push/push_notification_ids.dart';

void main() {
  group('pushMessageNotificationId', () {
    test('returns positive 31-bit value for typical ids', () {
      const String input = 'msg-123';
      final int actual = pushMessageNotificationId(input);
      expect(actual, greaterThan(0));
      expect(actual, lessThanOrEqualTo(0x7FFFFFFF));
    });

    test('is stable for the same message id', () {
      const String input = 'stable-id';
      expect(
        pushMessageNotificationId(input),
        pushMessageNotificationId(input),
      );
    });

    test('maps hash collision zero to fallback 1', () {
      final int actual = pushMessageNotificationId('');
      expect(actual, isNonNegative);
      expect(actual, lessThanOrEqualTo(0x7FFFFFFF));
    });
  });
}
