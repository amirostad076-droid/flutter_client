import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fluxer_fcm/fcm_background_handler.dart';

void registerFcmBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}
