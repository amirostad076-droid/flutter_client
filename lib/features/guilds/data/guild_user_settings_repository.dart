import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/talker.dart';
import 'package:fluxer_dart/export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'guild_user_settings_repository.g.dart';

@Riverpod(keepAlive: true)
GuildUserSettingsRepository guildUserSettingsRepository(Ref ref) {
  return GuildUserSettingsRepository(ref);
}

class GuildUserSettingsRepository {
  GuildUserSettingsRepository(this._ref);

  final Ref _ref;

  Future<void> toggleCategoryCollapsed({
    required String guildId,
    required String categoryId,
  }) async {
    final db = _ref.read(fluxerDatabaseProvider);
    final client = _ref.read(fluxerClientProvider);
    try {
      final existing = await db.userGuildSettingsDao.getByGuildId(guildId);
      final data = existing != null
          ? jsonDecode(existing.data) as Map<String, dynamic>
          : _defaultGuildSettingsData(guildId);

      final overridesMap =
          (data['channel_overrides'] as Map<String, dynamic>?) ??
          <String, dynamic>{};
      final rawOverride = overridesMap[categoryId] as Map<String, dynamic>?;
      final existingOverride = rawOverride != null
          ? ChannelOverrides.fromJson(rawOverride)
          : null;
      final isCollapsed = existingOverride?.collapsed ?? false;

      final newOverride = ChannelOverrides(
        collapsed: !isCollapsed,
        messageNotifications:
            existingOverride?.messageNotifications ??
            UserNotificationSettings.inherit,
        muted: existingOverride?.muted ?? false,
        muteConfig: existingOverride?.muteConfig,
        unreadBadges: existingOverride?.unreadBadges,
      );

      overridesMap[categoryId] = _channelOverrideToStorageJson(newOverride);
      data['channel_overrides'] = overridesMap;

      await db.userGuildSettingsDao.upsert(
        UserGuildSettingsTableCompanion(
          guildId: Value(guildId),
          data: Value(jsonEncode(data)),
        ),
      );

      unawaited(
        client.users.updateGuildSettingsForUser(
          guildId: guildId,
          body: UserGuildSettingsUpdateRequest(
            channelOverrides: {categoryId: newOverride},
          ),
        ),
      );
    } on Object catch (error, stackTrace) {
      talker.error(
        '[GuildUserSettingsRepository] Failed to toggle category collapsed',
        error,
        stackTrace,
      );
    }
  }
}

Map<String, dynamic> _defaultGuildSettingsData(String guildId) {
  return {
    'guild_id': guildId,
    'message_notifications': UserNotificationSettings.inherit.toJson(),
    'muted': false,
    'mute_config': null,
    'mobile_push': true,
    'suppress_everyone': false,
    'suppress_roles': false,
    'hide_muted_channels': false,
    'version': -1,
  };
}

Map<String, dynamic> _channelOverrideToStorageJson(ChannelOverrides override) {
  return {
    'collapsed': override.collapsed,
    'message_notifications': override.messageNotifications.toJson(),
    'muted': override.muted,
    if (override.muteConfig != null) 'mute_config': override.muteConfig!.toJson(),
    if (override.unreadBadges != null)
      'unread_badges': override.unreadBadges!.toJson(),
  };
}
