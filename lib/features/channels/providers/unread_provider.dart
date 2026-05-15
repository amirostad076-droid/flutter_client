import 'dart:async';

import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/providers/gateway_ready_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/features/channels/data/read_state_utils.dart';
import 'package:fluxer_app/features/channels/data/unread_permission_utils.dart';
import 'package:fluxer_app/features/channels/data/unread_settings_resolver.dart';
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

@riverpod
Stream<UnreadState> channelUnread(Ref ref, String channelId) {
  final db = ref.watch(fluxerDatabaseProvider);
  final currentUserId = ref.watch(currentUserIdProvider);
  ref.watch(gatewayReadyProvider);
  final controller = StreamController<UnreadState>();
  var disposed = false;

  Future<void> recompute() async {
    if (disposed) {
      return;
    }

    final channel = await db.channelDao.getChannelById(channelId);
    final readState = await db.readStateDao.getReadState(channelId);
    final lastCachedMessage = await db.messageDao.getLastMessage(channelId);
    final latestMessageId = channel?.lastMessageId ?? lastCachedMessage?.id;
    final rawMentionCount = readState?.mentionCount ?? 0;
    final visibleMentionCount =
        canShowMentionCount(
          channelLastMessageId: latestMessageId,
          isGuildChannel: channel != null,
          now: DateTime.now(),
        )
        ? rawMentionCount
        : 0;
    if (channel != null &&
        !await canReadChannelForUnread(
          database: db,
          channel: channel,
          currentUserId: currentUserId,
        )) {
      if (!disposed) {
        controller.add(const UnreadState());
      }
      return;
    }

    final guildSettings = channel == null
        ? null
        : await db.userGuildSettingsDao.getByGuildId(channel.guildId);
    final unreadSettings = channel == null
        ? null
        : resolveUnreadSettings(
            channel: channel,
            guildSettings: guildSettings == null
                ? null
                : decodeUserGuildSettings(guildSettings.data),
            now: DateTime.now(),
          );
    final mentionCount = (unreadSettings?.allowsMentionUnread ?? true)
        ? visibleMentionCount
        : 0;
    final fallbackAckMs = channel == null
        ? snowflakeTimestampMs(channelId)
        : await guildChannelFallbackAckMs(
            database: db,
            channel: channel,
            currentUserId: currentUserId,
          );
    final staleSuppressed = shouldSuppressStaleUnread(
      channelLastMessageId: latestMessageId,
      ackLastMessageId: readState?.lastMessageId,
      fallbackAckMs: fallbackAckMs,
      mentionCount: mentionCount,
      now: DateTime.now(),
    );
    final hasUnreadMessage =
        !staleSuppressed &&
        hasUnreadByReadState(
          channelLastMessageId: latestMessageId,
          ackLastMessageId: readState?.lastMessageId,
          fallbackAckMs: fallbackAckMs,
          mentionCount: 0,
        );
    final hasUnread =
        mentionCount > 0 ||
        ((unreadSettings?.allowsMessageUnread ?? true) && hasUnreadMessage);

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
  final settingsSub = db.userGuildSettingsDao.watchAll().listen(
    (_) => unawaited(recompute()),
  );

  unawaited(recompute());

  ref.onDispose(() {
    disposed = true;
    unawaited(channelSub.cancel());
    unawaited(readStateSub.cancel());
    unawaited(messageSub.cancel());
    unawaited(settingsSub.cancel());
    unawaited(controller.close());
  });

  return controller.stream;
}

