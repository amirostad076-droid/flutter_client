import 'dart:async';

import 'package:fluxer_app/core/push/local_push_notifications.dart';
import 'package:fluxer_app/core/push/push_message.dart';
import 'package:fluxer_app/core/push/push_service.dart';

class FirebaseMessagingPushService implements PushService {
  const FirebaseMessagingPushService();
  @override
  Future<void> requestPermissions() async {
    await LocalPushNotifications().requestDisplayPermission();
  }

  @override
  Future<void> initialize() async {
    // TODO(developer): Implement FCM initialization flow.
  }

  @override
  Future<String?> getToken() async {
    // TODO(developer): Return FCM device token.
    return null;
  }

  @override
  Stream<PushMessage> watchMessages() {
    // TODO(developer): Map FCM messages into PushMessage stream.
    return const Stream<PushMessage>.empty();
  }
}
