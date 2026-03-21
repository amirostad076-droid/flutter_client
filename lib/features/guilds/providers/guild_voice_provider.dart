import 'package:fluxeron/features/gateway/providers/gateway_event_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'guild_voice_provider.g.dart';

enum VoiceActivityType { none, voice, screenshare, video }

@riverpod
VoiceActivityType guildVoiceActivity(Ref ref, String guildId) {
  final voiceStates = ref.watch(voiceStatesMapProvider);

  var activity = VoiceActivityType.none;
  for (final vs in voiceStates.values) {
    if (vs.guildId != guildId || vs.channelId == null) {
      continue;
    }
    if (vs.selfVideo) {
      return VoiceActivityType.video;
    }
    if (vs.selfStream) {
      activity = VoiceActivityType.screenshare;
    } else if (activity == VoiceActivityType.none) {
      activity = VoiceActivityType.voice;
    }
  }
  return activity;
}
