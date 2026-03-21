import 'dart:async';
import 'dart:convert';

import 'package:fluxeron/core/providers/database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'unread_provider.g.dart';

class UnreadState {
  final bool hasUnread;
  final int mentionCount;

  const UnreadState({this.hasUnread = false, this.mentionCount = 0});
}

/// Voice channel type (2) and category type (4) don't contribute to
/// guild-level unread unless they have mentions.
const _voiceType = 2;
const _categoryType = 4;

@riverpod
Stream<UnreadState> channelUnread(Ref ref, String channelId) async* {
  final db = ref.watch(fluxerDatabaseProvider);

  await for (final readState in db.readStateDao.watchReadState(channelId)) {
    if (readState == null || readState.lastMessageId == null) {
      yield const UnreadState();
      continue;
    }

    // Use cached messages to determine latest message ID.
    final messages = await db.messageDao.getMessages(channelId, limit: 1);
    if (messages.isEmpty) {
      yield UnreadState(
        hasUnread: readState.mentionCount > 0,
        mentionCount: readState.mentionCount,
      );
      continue;
    }

    final latestMessageId = messages.last.id;
    final hasUnread = latestMessageId != readState.lastMessageId;

    yield UnreadState(
      hasUnread: hasUnread || readState.mentionCount > 0,
      mentionCount: readState.mentionCount,
    );
  }
}

@riverpod
Stream<UnreadState> serverUnread(Ref ref, String serverId) {
  final db = ref.watch(fluxerDatabaseProvider);
  final controller = StreamController<UnreadState>();
  var disposed = false;

  Future<void> recompute() async {
    if (disposed) {
      return;
    }

    final channels = await db.channelDao.getChannels(serverId);
    if (channels.isEmpty) {
      if (!disposed) {
        controller.add(const UnreadState());
      }
      return;
    }

    // Fetch mute settings for this guild.
    final guildSettings = await db.userGuildSettingsDao.getByGuildId(serverId);
    final mutedChannelIds = <String>{};
    var guildMuted = false;
    if (guildSettings != null) {
      final data = jsonDecode(guildSettings.data) as Map<String, dynamic>;
      guildMuted = data['muted'] as bool? ?? false;
      final overrides =
          data['channel_overrides'] as Map<String, dynamic>? ?? {};
      for (final entry in overrides.entries) {
        final override = entry.value as Map<String, dynamic>;
        if (override['muted'] == true) {
          mutedChannelIds.add(entry.key);
        }
      }
    }

    // Fetch read states for all channels in this server.
    final channelIds = channels.map((c) => c.id).toList();
    final readStates = await db.readStateDao
        .watchReadStatesForChannels(channelIds)
        .first;
    final readStateMap = {for (final rs in readStates) rs.channelId: rs};

    var anyUnread = false;
    var totalMentions = 0;

    for (final channel in channels) {
      if (channel.type == _categoryType) {
        continue;
      }

      final readState = readStateMap[channel.id];
      if (readState == null || readState.lastMessageId == null) {
        continue;
      }

      final mentions = readState.mentionCount;
      final isVoice = channel.type == _voiceType;
      final isMuted =
          guildMuted ||
          mutedChannelIds.contains(channel.id) ||
          mutedChannelIds.contains(channel.parentId);

      if (isVoice && mentions == 0) {
        continue;
      }

      if (isMuted && mentions == 0) {
        continue;
      }

      totalMentions += mentions;

      final channelLastMsg = channel.lastMessageId;
      if (channelLastMsg != null && channelLastMsg != readState.lastMessageId) {
        anyUnread = true;
      } else if (mentions > 0) {
        anyUnread = true;
      }
    }

    if (!disposed) {
      controller.add(
        UnreadState(hasUnread: anyUnread, mentionCount: totalMentions),
      );
    }
  }

  // Recompute when channels change (new messages update lastMessageId).
  final channelSub = db.channelDao
      .watchChannels(serverId)
      .listen((_) => unawaited(recompute()));

  // Recompute when any read state changes (user reads a channel).
  final readStateSub = db.readStateDao.watchReadStates().listen(
    (_) => unawaited(recompute()),
  );

  // Initial computation.
  unawaited(recompute());

  ref.onDispose(() {
    disposed = true;
    unawaited(channelSub.cancel());
    unawaited(readStateSub.cancel());
    unawaited(controller.close());
  });

  return controller.stream;
}
