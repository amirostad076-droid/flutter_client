import 'dart:convert';

import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'guild_mute_provider.g.dart';

class GuildMuteState {
  final bool isMuted;
  final DateTime? muteEndTime;

  const GuildMuteState({this.isMuted = false, this.muteEndTime});
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
    final muted = data['muted'] as bool? ?? false;
    if (!muted) {
      yield const GuildMuteState();
      continue;
    }

    final muteConfig = data['mute_config'] as Map<String, dynamic>?;
    final endTimeStr = muteConfig?['end_time'] as String?;
    DateTime? endTime;
    if (endTimeStr != null) {
      endTime = DateTime.tryParse(endTimeStr);
      if (endTime != null && endTime.isBefore(DateTime.now())) {
        yield const GuildMuteState();
        continue;
      }
    }

    yield GuildMuteState(isMuted: true, muteEndTime: endTime);
  }
}
