const String kFcmLocalNotificationMessageIdKey =
    '_local_notification_message_id';

int fcmPushMessageNotificationId(String messageId) {
  const int maxPositiveInt31 = 0x7FFFFFFF;
  final int hash = messageId.hashCode;
  final int masked = hash & maxPositiveInt31;
  if (masked != 0) {
    return masked;
  }
  return 1;
}

int? parseFcmPushBadgeCount(Map<String, String> payload) {
  final String? raw = payload['badge_count'];
  if (raw == null || raw.isEmpty) {
    return null;
  }
  final int? parsed = int.tryParse(raw);
  if (parsed == null || parsed < 0) {
    return null;
  }
  return parsed;
}
