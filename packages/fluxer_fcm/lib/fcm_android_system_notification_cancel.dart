import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluxer_fcm/fcm_push_notification_ids.dart';

int fcmJavaStringHashCode(String value) {
  int hash = 0;
  for (final int unit in value.codeUnits) {
    hash = hash * 31 + unit;
  }
  return hash;
}

Iterable<int> fcmSystemNotificationCancelIds(String messageId) {
  if (messageId.isEmpty) {
    return const <int>[];
  }
  final Set<int> ids = <int>{fcmPushMessageNotificationId(messageId)};
  final int javaHash = fcmJavaStringHashCode(messageId);
  ids.add(javaHash);
  final int positiveJavaHash = javaHash & 0x7FFFFFFF;
  if (positiveJavaHash != 0) {
    ids.add(positiveJavaHash);
  }
  return ids;
}

Future<void> cancelFcmSystemNotificationDuplicates(
  FlutterLocalNotificationsPlugin plugin, {
  required String messageId,
}) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return;
  }
  for (final int id in fcmSystemNotificationCancelIds(messageId)) {
    try {
      await plugin.cancel(id: id);
    } on Object catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[FcmSystemNotificationCancel] cancel id=$id failed: '
          '$error\n$stackTrace',
        );
      }
    }
  }
}
