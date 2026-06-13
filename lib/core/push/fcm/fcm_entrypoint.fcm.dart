import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:fluxer_app/core/build/push_provider_guard.dart';
import 'package:fluxer_app/core/push/local_push_notifications.dart';
import 'package:fluxer_app/core/push/push_message.dart';
import 'package:fluxer_fcm/fcm_message_mapper.dart';
import 'package:fluxer_fcm/fcm_push_message.dart';
import 'package:fluxer_fcm/firebase_options.dart';
import 'package:fluxer_fcm/fluxer_fcm_push_service.dart';

Future<void> bootstrapFcmIfNeeded() async {
  if (!PushProviderGuard.isFirebaseMessaging || !Platform.isAndroid) {
    return;
  }
  FirebaseMessaging.onBackgroundMessage(fcmBackgroundMessageHandler);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FluxerFcmPushService.instance.initialize();
}

@pragma('vm:entry-point')
Future<void> fcmBackgroundMessageHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  if (kDebugMode) {
    debugPrint(
      '[FCM] background message id=${message.messageId} data=${message.data}',
    );
  }
  if (message.notification != null) {
    return;
  }
  final FcmPushMessage mapped = mapRemoteMessage(message);
  final LocalPushNotifications localPush = LocalPushNotifications();
  final bool ready = await localPush.ensureInitialized();
  if (!ready) {
    if (kDebugMode) {
      debugPrint('[FCM] background local notifications not initialized');
    }
    return;
  }
  await localPush.showPushMessage(
    PushMessage(
      id: mapped.id,
      title: mapped.title,
      body: mapped.body,
      payload: mapped.payload,
    ),
  );
}
