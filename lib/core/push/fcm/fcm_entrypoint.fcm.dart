import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:fluxer_app/core/build/push_provider_guard.dart';
import 'package:fluxer_fcm/firebase_options.dart';

void bootstrapFcmIfNeeded() {
  if (!PushProviderGuard.isFirebaseMessaging || !Platform.isAndroid) {
    return;
  }
  FirebaseMessaging.onBackgroundMessage(fcmBackgroundMessageHandler);
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
}
