import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:fluxer_fcm/fcm_local_notifications.dart';
import 'package:fluxer_fcm/fcm_message_mapper.dart';
import 'package:fluxer_fcm/firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    final mapped = mapRemoteMessage(message);
    final FcmLocalNotifications localPush = FcmLocalNotifications();
    final bool ready = await localPush.ensureInitialized();
    if (!ready) {
      if (kDebugMode) {
        debugPrint('[FCM] background: local notifications not initialized');
      }
      return;
    }
    await localPush.showPushMessage(mapped);
    if (kDebugMode) {
      debugPrint(
        '[FCM] background notification id=${mapped.id} '
        'payload=${mapped.payload}',
      );
    }
  } on Object catch (e, st) {
    if (kDebugMode) {
      debugPrint('[FCM] background handler failed: $e\n$st');
    }
  }
}
