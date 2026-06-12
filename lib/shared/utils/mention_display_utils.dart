import 'package:fluxer_app/shared/utils/guild_user_display.dart';

String shortMentionWireIdFallback(String userId) {
  if (userId.length <= 10) {
    return userId;
  }
  return '${userId.substring(0, 8)}…';
}

String resolveMentionUserDisplayName({
  required String userId,
  GuildUserDisplay? guildDisplay,
}) {
  if (guildDisplay != null) {
    return guildDisplay.displayName;
  }
  return shortMentionWireIdFallback(userId);
}
