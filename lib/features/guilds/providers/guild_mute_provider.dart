import 'dart:convert';

import 'package:fluxer_dart/export.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:fluxer_app/core/providers/database_provider.dart';

part 'guild_mute_provider.g.dart';

class GuildMuteState {
  final bool isMuted;
  final DateTime? muteEndTime;
  final bool hideMutedChannels;

  const GuildMuteState({
    this.isMuted = false,
    this.muteEndTime,
    this.hideMutedChannels = false,
  });
}

@riverpod
Stream<GuildMuteState> guildMute(Ref ref, String guildId) async* {
  final db = ref.watch(fluxerDatabaseProvider);

  await for (final settings in db.userGuildSettingsDao.watchByGuildId(
    guildId,
  )) {
    if (settings == null) {
      yield const GuildMuteState();
      continue;
    }

    final data = jsonDecode(settings.data) as Map<String, dynamic>;
    final gs = UserGuildSettingsResponse.fromJson(data);

    if (!gs.muted) {
      yield GuildMuteState(hideMutedChannels: gs.hideMutedChannels);
      continue;
    }

    final endTimeStr = gs.muteConfig?.endTime;
    DateTime? endTime;
    if (endTimeStr != null) {
      endTime = DateTime.tryParse(endTimeStr);
      if (endTime != null && endTime.isBefore(DateTime.now())) {
        yield GuildMuteState(hideMutedChannels: gs.hideMutedChannels);
        continue;
      }
    }

    yield GuildMuteState(
      isMuted: true,
      muteEndTime: endTime,
      hideMutedChannels: gs.hideMutedChannels,
    );
  }
}
