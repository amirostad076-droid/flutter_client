import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/features/gateway/providers/gateway_event_providers.dart';
import 'package:fluxer_app/features/guilds/domain/guild.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'guild_voice_provider.g.dart';

enum VoiceActivityType { none, voice, screenshare, video }

class VoiceParticipantRow {
  const VoiceParticipantRow({
    required this.isScreenshare,
    required this.avatarUrls,
  });

  final bool isScreenshare;
  final List<String> avatarUrls;
}

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

@riverpod
Future<List<VoiceParticipantRow>> guildVoiceParticipants(
  Ref ref,
  String guildId,
) async {
  final voiceStates = ref.watch(voiceStatesMapProvider);
  final db = ref.watch(fluxerDatabaseProvider);

  final voiceUserIds = <String>[];
  final screenshareUserIds = <String>[];

  for (final vs in voiceStates.values) {
    if (vs.guildId != guildId || vs.channelId == null) {
      continue;
    }
    if (vs.selfStream) {
      screenshareUserIds.add(vs.userId);
    } else {
      voiceUserIds.add(vs.userId);
    }
  }

  if (voiceUserIds.isEmpty && screenshareUserIds.isEmpty) {
    return const [];
  }

  final allUserIds = {...voiceUserIds, ...screenshareUserIds};
  final users = await db.userDao.getUsersByIds(allUserIds.toList());
  final userMap = {for (final u in users) u.id: u};

  String? avatarUrl(String userId) {
    final user = userMap[userId];
    if (user?.avatar == null) {
      return null;
    }
    return '$fluxerMediaCdn/avatars/${user!.id}/${user.avatar}.png';
  }

  final rows = <VoiceParticipantRow>[];
  if (screenshareUserIds.isNotEmpty) {
    rows.add(
      VoiceParticipantRow(
        isScreenshare: true,
        avatarUrls: screenshareUserIds
            .map(avatarUrl)
            .whereType<String>()
            .take(3)
            .toList(),
      ),
    );
  }
  if (voiceUserIds.isNotEmpty) {
    rows.add(
      VoiceParticipantRow(
        isScreenshare: false,
        avatarUrls: voiceUserIds
            .map(avatarUrl)
            .whereType<String>()
            .take(3)
            .toList(),
      ),
    );
  }
  return rows;
}
