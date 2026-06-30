import 'package:firebase_messaging/firebase_messaging.dart';

/// Data only FCM messages need a local notification in the background isolate.
/// Hybrid notification + data messages are displayed by the Android system.
bool shouldDisplayFcmBackgroundLocalNotification(RemoteMessage message) {
  return message.notification == null;
}
