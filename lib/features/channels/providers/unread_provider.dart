import 'dart:async';
import 'dart:convert';

import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/features/channels/data/read_state_utils.dart';
import 'package:fluxer_dart/export.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'unread_provider.g.dart';

class UnreadState {
  final bool hasUnread;
  final int mentionCount;
  final bool hasUnreadPins;

  const UnreadState({
    this.hasUnread = false,
    this.mentionCount = 0,
    this.hasUnreadPins = false,
  });
}

/// Voice channel type (2) and category type (4) don't contribute to
/// guild-level unread unless they have mentions.
const _voiceType = 2;
const _categoryType = 4;

@riverpod
Stream<UnreadState> channelUnread(Ref ref, String channelId) {
  final db = ref.watch(fluxerDatabaseProvider);
  final controller = StreamController<UnreadState>();
  var disposed = false;

  Future<void> recompute() async {
    if (disposed) {
      return;
    }

    final channel = await db.channelDao.getChannelById(channelId);
    final readState = await db.readStateDao.getReadState(channelId);
    final messages = await db.messageDao.getMessages(channelId, limit: 1);
    final latestCachedMessageId = messages.isEmpty ? null : messages.last.id;
    final latestMessageId = channel?.lastMessageId ?? latestCachedMessageId;
    final mentionCount = readState?.mentionCount ?? 0;
    final fallbackAckMs = snowflakeTimestampMs(channel?.id ?? channelId);
    final staleSuppressed = shouldSuppressStaleUnread(
      channelLastMessageId: latestMessageId,
      ackLastMessageId: readState?.lastMessageId,
      fallbackAckMs: fallbackAckMs,
      mentionCount: mentionCount,
      now: DateTime.now(),
    );
    final hasUnread =
        !staleSuppressed &&
        hasUnreadByReadState(
          channelLastMessageId: latestMessageId,
          ackLastMessageId: readState?.lastMessageId,
          fallbackAckMs: fallbackAckMs,
          mentionCount: mentionCount,
        );

    final hasPinUnread = hasUnreadPins(
      channelLastPinTimestamp: channel?.lastPinTimestamp,
      ackLastPinTimestamp: readState?.lastPinTimestamp,
    );

    if (!disposed) {
      controller.add(
        UnreadState(
          hasUnread: hasUnread,
          mentionCount: mentionCount,
          hasUnreadPins: hasPinUnread,
        ),
      );
    }
  }

  final channelSub = db.channelDao
      .watchChannelById(channelId)
      .listen((_) => unawaited(recompute()));
  final readStateSub = db.readStateDao
      .watchReadState(channelId)
      .listen((_) => unawaited(recompute()));
  final messageSub = db.messageDao
      .watchMessages(channelId)
      .listen((_) => unawaited(recompute()));

  unawaited(recompute());

  ref.onDispose(() {
    disposed = true;
    unawaited(channelSub.cancel());
    unawaited(readStateSub.cancel());
    unawaited(messageSub.cancel());
    unawaited(controller.close());
  });

  return controller.stream;
}

@riverpod
Stream<UnreadState> serverUnread(Ref ref, String guildId) {
  final db = ref.watch(fluxerDatabaseProvider);
  final controller = StreamController<UnreadState>();
  var disposed = false;

  Future<void> recompute() async {
    if (disposed) {
      return;
    }

    final channels = await db.channelDao.getChannels(guildId);
    if (channels.isEmpty) {
      if (!disposed) {
        controller.add(const UnreadState());
      }
      return;
    }

    final guildSettings = await db.userGuildSettingsDao.getByGuildId(guildId);
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
      final mentions = readState?.mentionCount ?? 0;
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
      final fallbackAckMs = snowflakeTimestampMs(channel.id);
      final staleSuppressed = shouldSuppressStaleUnread(
        channelLastMessageId: channelLastMsg,
        ackLastMessageId: readState?.lastMessageId,
        fallbackAckMs: fallbackAckMs,
        mentionCount: mentions,
        now: DateTime.fromMillisecondsSinceEpoch(nowMs),
      );
      if (staleSuppressed) {
        continue;
      }

      totalMentions += mentions;

      if (hasUnreadByReadState(
        channelLastMessageId: channelLastMsg,
        ackLastMessageId: readState?.lastMessageId,
        fallbackAckMs: fallbackAckMs,
        mentionCount: mentions,
      )) {
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
      .watchChannels(guildId)
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
