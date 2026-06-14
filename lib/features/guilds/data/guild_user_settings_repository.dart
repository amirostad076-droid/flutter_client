import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/talker.dart';
import 'package:fluxer_dart/export.dart';
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
    try {
      final overrides = await _loadChannelOverridesFromCache(guildId);
      final previous = overrides[categoryId];
      await updateChannelOverride(
        guildId: guildId,
        channelId: categoryId,
        collapsed: !(previous?.collapsed ?? false),
      );
    } on Object catch (error, stackTrace) {
      talker.error(
        '[GuildUserSettingsRepository] Failed to toggle category collapsed',
        error,
        stackTrace,
      );
    }
  }

  Future<void> updateChannelOverride({
    required String guildId,
    required String channelId,
    bool? muted,
    int? durationSeconds,
    UserNotificationSettings? messageNotifications,
    bool? collapsed,
  }) async {
    try {
      final overrides = await _loadChannelOverridesFromCache(guildId);
      final previous = overrides[channelId];
      final override = _mergeChannelOverride(
        previous: previous,
        muted: muted,
        durationSeconds: durationSeconds,
        messageNotifications: messageNotifications,
        collapsed: collapsed,
      );
      overrides[channelId] = override;
      await _patchAndPersistChannelOverrides(
        guildId: guildId,
        channelOverrides: overrides,
      );
    } on Object catch (error, stackTrace) {
      talker.error(
        '[GuildUserSettingsRepository] Failed to update channel override',
        error,
        stackTrace,
      );
      rethrow;
    }
  }

  Future<void> removeChannelOverride({
    required String guildId,
    required String channelId,
  }) async {
    final overrides = await _loadChannelOverridesFromCache(guildId);
    overrides.remove(channelId);
    await _patchAndPersistChannelOverrides(
      guildId: guildId,
      channelOverrides: overrides,
    );
  }

  Future<Map<String, ChannelOverrides>> _loadChannelOverridesFromCache(
    String guildId,
  ) async {
    final db = _ref.read(fluxerDatabaseProvider);
    final existing = await db.userGuildSettingsDao.getByGuildId(guildId);
    if (existing == null) {
      return <String, ChannelOverrides>{};
    }
    try {
      final settings = UserGuildSettingsResponse.fromJson(
        jsonDecode(existing.data) as Map<String, dynamic>,
      );
      return Map<String, ChannelOverrides>.from(
        settings.channelOverrides ?? const {},
      );
    } on Object {
      return <String, ChannelOverrides>{};
    }
  }

  Future<void> _patchAndPersistChannelOverrides({
    required String guildId,
    required Map<String, ChannelOverrides> channelOverrides,
  }) async {
    final client = _ref.read(fluxerClientProvider);
    final db = _ref.read(fluxerDatabaseProvider);
    final body = UserGuildSettingsUpdateRequest(
      channelOverrides: channelOverrides.isEmpty ? null : channelOverrides,
    );
    final UserGuildSettingsResponse response;
    if (guildId == '@me') {
      response = await client.users.updateDmNotificationSettings(body: body);
    } else {
      response = await client.users.updateGuildSettingsForUser(
        guildId: guildId,
        body: body,
      );
    }
    await db.userGuildSettingsDao.upsert(
      UserGuildSettingsTableCompanion(
        guildId: Value(_storageGuildId(response.guildId, guildId)),
        data: Value(jsonEncode(response.toJson())),
      ),
    );
  }

  String _storageGuildId(String? responseGuildId, String requestGuildId) {
    if (requestGuildId == '@me') {
      return '@me';
    }
    return responseGuildId ?? requestGuildId;
  }
}

ChannelOverrides _mergeChannelOverride({
  required ChannelOverrides? previous,
  bool? muted,
  int? durationSeconds,
  UserNotificationSettings? messageNotifications,
  bool? collapsed,
}) {
  final bool? resolvedMuted = muted ?? previous?.muted;
  final isExplicitUnmute = muted == false;
  final isExplicitMute = muted ?? false;
  final ChannelOverridesMuteConfig? muteConfig = isExplicitUnmute
      ? null
      : isExplicitMute
      ? ChannelOverridesMuteConfig(
          endTime: durationSeconds == null
              ? null
              : DateTime.now()
                    .add(Duration(seconds: durationSeconds))
                    .toUtc()
                    .toIso8601String(),
          selectedTimeWindow: durationSeconds ?? -1,
        )
      : previous?.muteConfig;
  return ChannelOverrides(
    collapsed: collapsed ?? previous?.collapsed ?? false,
    messageNotifications:
        messageNotifications ??
        previous?.messageNotifications ??
        UserNotificationSettings.inherit,
    muted: resolvedMuted ?? false,
    muteConfig: muteConfig,
    unreadBadges: previous?.unreadBadges,
  );
}
