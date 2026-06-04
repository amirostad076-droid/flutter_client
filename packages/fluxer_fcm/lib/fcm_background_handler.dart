import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:fluxer_fcm/firebase_options.dart';

/// Background FCM handler. Notification display is handled by the FCM SDK when
/// the server includes a notification payload; this only ensures Firebase is
/// initialized in the background isolate for data processing.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  if (kDebugMode) {
    debugPrint(
      '[FCM] background message id=${message.messageId} '
      'data=${message.data}',
    );
  }
}
