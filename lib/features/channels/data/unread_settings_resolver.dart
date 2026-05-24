import 'dart:convert';

import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_dart/export.dart';

class ResolvedUnreadSettings {
  const ResolvedUnreadSettings({
    required this.isMuted,
    required this.allowsMessageUnread,
    required this.allowsGuildMessageUnread,
    required this.allowsMentionUnread,
  });

  final bool isMuted;
  final bool allowsMessageUnread;
  final bool allowsGuildMessageUnread;
  final bool allowsMentionUnread;
}

UserGuildSettingsResponse? decodeUserGuildSettings(String data) {
  try {
    return UserGuildSettingsResponse.fromJson(
      jsonDecode(data) as Map<String, dynamic>,
    );
  } on Object {
    return null;
  }
}

ResolvedUnreadSettings resolveUnreadSettings({
  required db.Channel channel,
  required UserGuildSettingsResponse? guildSettings,
  required DateTime now,
}) {
  final overrides = guildSettings?.channelOverrides ?? const {};
  final directOverride = overrides[channel.id];
  final parentOverride = channel.parentId == null
      ? null
      : overrides[channel.parentId!];
  final isMuted =
      _isGuildMuted(guildSettings, now) ||
      _isChannelMuted(parentOverride, now) ||
      _isChannelMuted(directOverride, now);

  final explicitBadgeLevel = _resolvedUnreadBadgeLevel(
    directOverride: directOverride,
    parentOverride: parentOverride,
    guildSettings: guildSettings,
  );
  final badgeLevel = explicitBadgeLevel ?? UserNotificationSettings.allMessages;

  return ResolvedUnreadSettings(
    isMuted: isMuted,
    allowsMessageUnread: badgeLevel == UserNotificationSettings.allMessages,
    allowsGuildMessageUnread: explicitBadgeLevel == null
        ? !isMuted
        : explicitBadgeLevel == UserNotificationSettings.allMessages,
    allowsMentionUnread: badgeLevel != UserNotificationSettings.noMessages,
  );
}

bool _isGuildMuted(UserGuildSettingsResponse? settings, DateTime now) {
  if (settings?.muted != true) {
    return false;
  }
  return _isMuteActive(settings?.muteConfig?.endTime, now);
}

bool isChannelOverrideMuted(
  ChannelOverrides? override, {
  required DateTime now,
}) {
  return _isChannelMuted(override, now);
}

bool _isChannelMuted(ChannelOverrides? override, DateTime now) {
  if (override?.muted != true) {
    return false;
  }
  return _isMuteActive(override?.muteConfig?.endTime, now);
}

bool _isMuteActive(String? endTime, DateTime now) {
  if (endTime == null || endTime.isEmpty) {
    return true;
  }
  final parsed = DateTime.tryParse(endTime);
  return parsed == null || parsed.isAfter(now);
}

UserNotificationSettings? resolveExplicitUnreadBadgeLevel({
  required db.Channel channel,
  required UserGuildSettingsResponse? guildSettings,
}) {
  final overrides = guildSettings?.channelOverrides ?? const {};
  return _resolvedUnreadBadgeLevel(
    directOverride: overrides[channel.id],
    parentOverride: channel.parentId == null
        ? null
        : overrides[channel.parentId!],
    guildSettings: guildSettings,
  );
}

UserNotificationSettings? _resolvedUnreadBadgeLevel({
  required ChannelOverrides? directOverride,
  required ChannelOverrides? parentOverride,
  required UserGuildSettingsResponse? guildSettings,
}) {
  return _explicitLevel(directOverride?.unreadBadges) ??
      _explicitLevel(parentOverride?.unreadBadges) ??
      _explicitLevel(guildSettings?.unreadBadges);
}

UserNotificationSettings? _explicitLevel(UserNotificationSettings? level) {
  if (level == null ||
      level == UserNotificationSettings.inherit ||
      level == UserNotificationSettings.$unknown) {
    return null;
  }
  return level;
}
