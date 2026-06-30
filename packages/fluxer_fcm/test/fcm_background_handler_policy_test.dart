import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:test/test.dart';
import 'package:fluxer_fcm/fcm_background_handler_policy.dart';

void main() {
  group('shouldDisplayFcmBackgroundLocalNotification', () {
    test('displays for data-only messages', () {
      final RemoteMessage input = RemoteMessage(
        messageId: 'msg-data',
        data: <String, String>{'channel_id': '2', 'url': '/channels/@me/2/1'},
      );
      expect(shouldDisplayFcmBackgroundLocalNotification(input), isTrue);
    });

    test('skips hybrid messages handled by the Android system', () {
      final RemoteMessage input = RemoteMessage(
        messageId: 'msg-hybrid',
        data: <String, String>{'channel_id': '2', 'url': '/channels/@me/2/1'},
        notification: const RemoteNotification(title: 'alice', body: 'hello'),
      );
      expect(shouldDisplayFcmBackgroundLocalNotification(input), isFalse);
    });
  });
}
