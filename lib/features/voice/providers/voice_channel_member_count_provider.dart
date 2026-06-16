import 'package:fluxer_app/features/gateway/providers/gateway_event_providers.dart';
import 'package:fluxer_dart/gateway.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'voice_channel_member_count_provider.g.dart';

/// Distinct connected user count for a guild voice channel.
///
/// [guildChannelKey] is `'<guildId>|<channelId>'`
/// (see `voiceChannelParticipantsFamilyKey`). Row-scoped replacement for
/// watching the whole [voiceStatesMapProvider] from each sidebar tile.
@riverpod
int voiceChannelMemberCount(Ref ref, String guildChannelKey) {
  final int sep = guildChannelKey.indexOf('|');
  final String guildId = sep < 0
      ? guildChannelKey
      : guildChannelKey.substring(0, sep);
  final String channelId = sep < 0 ? '' : guildChannelKey.substring(sep + 1);
  final Map<String, VoiceState> states = ref.watch(voiceStatesMapProvider);
  final Set<String> userIds = <String>{};
  for (final VoiceState vs in states.values) {
    if (vs.channelId == channelId && vs.guildId == guildId) {
      userIds.add(vs.userId);
    }
  }
  return userIds.length;
}
