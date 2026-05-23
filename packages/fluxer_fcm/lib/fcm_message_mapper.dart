import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fluxer_fcm/fcm_push_message.dart';

const String kFcmDefaultTitle = 'Fluxer';

FcmPushMessage mapRemoteMessage(RemoteMessage message) {
  final Map<String, String> dataPayload = _stringifyMap(message.data);
  final RemoteNotification? notification = message.notification;
  final String? title = notification?.title ?? dataPayload['title'];
  final String? body = notification?.body ?? dataPayload['body'];
  final String id = _resolveMessageId(message, dataPayload);
  return FcmPushMessage(
    id: id,
    title: title ?? kFcmDefaultTitle,
    body: body ?? 'New message',
    payload: dataPayload,
  );
}

String _resolveMessageId(
  RemoteMessage message,
  Map<String, String> dataPayload,
) {
  final String? messageId = message.messageId;
  if (messageId != null && messageId.isNotEmpty) {
    return messageId;
  }
  final String? dataId = dataPayload['message_id'] ?? dataPayload['id'];
  if (dataId != null && dataId.isNotEmpty) {
    return dataId;
  }
  return DateTime.now().microsecondsSinceEpoch.toString();
}

Map<String, String> _stringifyMap(Map<String, dynamic> source) {
  final Map<String, String> result = <String, String>{};
  for (final MapEntry<String, dynamic> entry in source.entries) {
    final dynamic value = entry.value;
    if (value == null) {
      continue;
    }
    result[entry.key] = value.toString();
  }
  return result;
}
