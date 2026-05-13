/// Maps a push message id to a 32-bit notification id for local notifications.
int pushMessageNotificationId(String messageId) {
  const int maxPositiveInt31 = 0x7FFFFFFF;
  final int hash = messageId.hashCode;
  final int masked = hash & maxPositiveInt31;
  if (masked != 0) {
    return masked;
  }
  return 1;
}
