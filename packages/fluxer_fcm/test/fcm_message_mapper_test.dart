import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_fcm/fcm_message_mapper.dart';
import 'package:fluxer_fcm/fcm_push_message.dart';

void main() {
  group('mapRemoteMessage', () {
    test('maps notification and data fields', () {
      final RemoteMessage input = RemoteMessage(
        messageId: 'msg-1',
        data: <String, String>{
          'channel_id': '2',
          'url': '/channels/3/2/1',
        },
        notification: const RemoteNotification(
          title: 'alice',
          body: 'hello',
        ),
      );
      final FcmPushMessage message = mapRemoteMessage(input);
      expect(message.id, 'msg-1');
      expect(message.title, 'alice');
      expect(message.body, 'hello');
      expect(message.payload['channel_id'], '2');
      expect(message.payload['url'], '/channels/3/2/1');
    });

    test('falls back to data title and message_id', () {
      final RemoteMessage input = RemoteMessage(
        data: <String, String>{
          'title': 'from-data',
          'body': 'body-data',
          'message_id': '42',
        },
      );
      final FcmPushMessage message = mapRemoteMessage(input);
      expect(message.id, '42');
      expect(message.title, 'from-data');
      expect(message.body, 'body-data');
    });
  });
}
