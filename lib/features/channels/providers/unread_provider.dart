import 'dart:async';
import 'dart:convert';

import 'package:fluxer_dart/export.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/shared/utils/snowflake_time.dart';

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

/// Messages older than 7 days are suppressed from unread indicators
/// unless the channel was recently visited or has mentions.
const _oldMessageThreshold = Duration(days: 7);

/// A channel is considered "recently visited" if it was acked within
/// the last 3 days.
const _recentVisitThreshold = Duration(days: 3);

/// Extracts millisecond timestamp from a snowflake ID, or 0 if invalid.
int _snowflakeTimestamp(String? id) {
  if (id == null) {
    return 0;
  }
  final parsed = int.tryParse(id);
  if (parsed == null) {
    return 0;
  }
  return (parsed >> 22) + kSnowflakeEpochMs;
}

@riverpod
Stream<UnreadState> channelUnread(Ref ref, String channelId) async* {
  final db = ref.watch(fluxerDatabaseProvider);

  await for (final readState in db.readStateDao.watchReadState(channelId)) {
    if (readState == null || readState.lastMessageId == null) {
      yield const UnreadState();
      continue;
    }

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

    final guildSettings = await db.userGuildSettingsDao.getByGuildId(serverId);
    final mutedChannelIds = <String>{};
    var guildMuted = false;
    if (guildSettings != null) {
      final gs = UserGuildSettingsResponse.fromJson(
        jsonDecode(guildSettings.data) as Map<String, dynamic>,
      );
      guildMuted = gs.muted;
      final overrides = gs.channelOverrides ?? {};
      for (final entry in overrides.entries) {
        if (entry.value.muted) {
          mutedChannelIds.add(entry.key);
        }
      }
    }

    final channelIds = channels.map((c) => c.id).toList();
    final readStates = await db.readStateDao
        .watchReadStatesForChannels(channelIds)
        .first;
    final readStateMap = {for (final rs in readStates) rs.channelId: rs};

    final nowMs = DateTime.now().millisecondsSinceEpoch;
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

      final channelLastMsg = channel.lastMessageId;
      final lastMsgTs = _snowflakeTimestamp(channelLastMsg);
      final ackTs = _snowflakeTimestamp(readState.lastMessageId);

      // Suppress old unreads: messages older than 7 days are hidden unless
      // the channel was recently visited (acked within 3 days) or has
      // mentions.
      if (lastMsgTs > 0 &&
          lastMsgTs < nowMs - _oldMessageThreshold.inMilliseconds) {
        final recentlyVisited =
            ackTs > 0 &&
            ackTs > nowMs - _recentVisitThreshold.inMilliseconds;
        if (!recentlyVisited && mentions == 0) {
          continue;
        }
      }

      totalMentions += mentions;

      // Use snowflake timestamp comparison: unread if ack < last message.
      if (lastMsgTs > 0 && ackTs < lastMsgTs) {
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

  final channelSub = db.channelDao
      .watchChannels(serverId)
      .listen((_) => unawaited(recompute()));

  final readStateSub = db.readStateDao.watchReadStates().listen(
    (_) => unawaited(recompute()),
  );

  unawaited(recompute());

  ref.onDispose(() {
    disposed = true;
    unawaited(channelSub.cancel());
    unawaited(readStateSub.cancel());
    unawaited(controller.close());
  });

  return controller.stream;
}
