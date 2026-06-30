import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_fcm/fcm_background_handler_policy.dart';
import 'package:fluxer_fcm/fcm_message_mapper.dart';
import 'package:fluxer_fcm/fcm_push_message.dart';

void main() {
  group('fcm background handler policy', () {
    test('maps data-only messages for local display', () {
      final RemoteMessage input = RemoteMessage(
        messageId: 'bg-data',
        data: <String, String>{
          'title': 'alice',
          'body': 'hello',
          'channel_id': 'dm-1',
          'message_id': 'msg-9',
          'url': '/channels/@me/dm-1/msg-9',
        },
      );
      final FcmPushMessage mapped = mapRemoteMessage(input);
      expect(shouldDisplayFcmBackgroundLocalNotification(input), isTrue);
      expect(mapped.payload['url'], '/channels/@me/dm-1/msg-9');
      expect(mapped.payload['channel_id'], 'dm-1');
    });

    test(
      'skips local display for hybrid messages but keeps navigation payload',
      () {
        final RemoteMessage input = RemoteMessage(
          messageId: 'bg-hybrid',
          data: <String, String>{
            'channel_id': 'dm-1',
            'message_id': 'msg-9',
            'url': '/channels/@me/dm-1/msg-9',
          },
          notification: const RemoteNotification(title: 'alice', body: 'hello'),
        );
        final FcmPushMessage mapped = mapRemoteMessage(input);
        expect(shouldDisplayFcmBackgroundLocalNotification(input), isFalse);
        expect(mapped.payload['url'], '/channels/@me/dm-1/msg-9');
      },
    );
  });
}
