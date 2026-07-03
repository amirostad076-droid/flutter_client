import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_fcm/fcm_android_system_notification_cancel.dart';
import 'package:fluxer_fcm/fcm_push_notification_ids.dart';

void main() {
  group('fcmJavaStringHashCode', () {
    test('matches Java String.hashCode for sample values', () {
      expect(fcmJavaStringHashCode(''), 0);
      expect(fcmJavaStringHashCode('a'), 97);
      expect(fcmJavaStringHashCode('msg-1'), 104190181);
    });
  });

  group('fcmSystemNotificationCancelIds', () {
    test('includes dart and java hash ids', () {
      const String messageId = 'msg-1';
      final Iterable<int> ids = fcmSystemNotificationCancelIds(messageId);
      expect(ids, contains(fcmPushMessageNotificationId(messageId)));
      expect(ids, contains(fcmJavaStringHashCode(messageId)));
    });

    test('returns empty for blank message id', () {
      expect(fcmSystemNotificationCancelIds(''), isEmpty);
    });
  });
}
