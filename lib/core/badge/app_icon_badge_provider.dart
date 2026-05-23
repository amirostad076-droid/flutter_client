import 'dart:async';

import 'package:fluxer_app/core/badge/app_icon_badge.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/providers/gateway_ready_provider.dart';
import 'package:fluxer_app/features/channels/data/read_state_utils.dart';
import 'package:fluxer_app/features/dm/providers/dm_mute_provider.dart';
import 'package:fluxer_app/features/friends/providers/friend_providers.dart';
import 'package:fluxer_app/features/guilds/providers/guild_read_state_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_icon_badge_provider.g.dart';

@Riverpod(keepAlive: true)
class AppIconBadge extends _$AppIconBadge {
  StreamSubscription<List<DmChannel>>? _dmSub;
  StreamSubscription<List<ReadState>>? _readStateSub;
  List<DmChannel> _dmRows = const [];
  Map<String, ReadState> _readStateByChannel = const {};
  int _dmMentionCount = 0;
  bool _dmHasPlainUnread = false;

  @override
  AppIconBadgeValue build() {
    final bool gatewayReady = ref.watch(gatewayReadyProvider);
    if (!gatewayReady) {
      return const AppIconBadgeValue(count: 0);
    }
    final Map<String, GuildReadStateEntry> guildStates = ref.watch(
      guildReadStateProvider,
    );
    final int pendingFriends =
        ref.watch(pendingFriendRequestCountProvider).value ?? 0;
    ref.listen<AsyncValue<Set<String>>>(mutedDmChannelIdsProvider, (_, __) {
      unawaited(_recomputeDmTotals());
    });
    final db = ref.watch(fluxerDatabaseProvider);
    unawaited(_dmSub?.cancel());
    unawaited(_readStateSub?.cancel());
    _dmSub = db.dmChannelDao.watchDmChannels().listen((rows) {
      _dmRows = rows;
      unawaited(_recomputeDmTotals());
    });
    _readStateSub = db.readStateDao.watchReadStates().listen((rows) {
      _readStateByChannel = {for (final r in rows) r.channelId: r};
      unawaited(_recomputeDmTotals());
    });
    ref.onDispose(() {
      unawaited(_dmSub?.cancel());
      unawaited(_readStateSub?.cancel());
    });
    unawaited(_recomputeDmTotals());
    return _computeFromParts(
      guildStates: guildStates,
      pendingFriendRequestCount: pendingFriends,
    );
  }

  Future<void> _recomputeDmTotals() async {
    if (_dmRows.isEmpty) {
      _dmMentionCount = 0;
      _dmHasPlainUnread = false;
      _syncState();
      return;
    }
    final db = ref.read(fluxerDatabaseProvider);
    final channelIds = _dmRows.map((r) => r.id).toList();
    final lastMessages = await db.messageDao.getLastMessageForChannels(
      channelIds,
    );
    final mutedIds = ref.read(mutedDmChannelIdsProvider).value ?? const {};
    final now = DateTime.now();
    var mentionTotal = 0;
    var hasPlainUnread = false;
    for (final dm in _dmRows) {
      final readState = _readStateByChannel[dm.id];
      final latestMessageId = dm.lastMessageId ?? lastMessages[dm.id]?.id;
      final rawMentions = readState?.mentionCount ?? 0;
      final visibleMentions =
          canShowMentionCount(
            channelLastMessageId: latestMessageId,
            isGuildChannel: false,
            now: now,
          )
          ? rawMentions
          : 0;
      mentionTotal += visibleMentions;
      if (visibleMentions > 0 || mutedIds.contains(dm.id)) {
        continue;
      }
      if (hasUnreadByReadState(
        channelLastMessageId: latestMessageId,
        ackLastMessageId: readState?.lastMessageId,
        fallbackAckMs: snowflakeTimestampMs(dm.id),
        mentionCount: 0,
      )) {
        hasPlainUnread = true;
      }
    }
    _dmMentionCount = mentionTotal;
    _dmHasPlainUnread = hasPlainUnread;
    _syncState();
  }

  void _syncState() {
    final Map<String, GuildReadStateEntry> guildStates = ref.read(
      guildReadStateProvider,
    );
    final int pendingFriends =
        ref.read(pendingFriendRequestCountProvider).value ?? 0;
    state = _computeFromParts(
      guildStates: guildStates,
      pendingFriendRequestCount: pendingFriends,
    );
  }

  AppIconBadgeValue _computeFromParts({
    required Map<String, GuildReadStateEntry> guildStates,
    required int pendingFriendRequestCount,
  }) {
    var guildMentionCount = 0;
    var guildHasPlainUnread = false;
    for (final entry in guildStates.values) {
      guildMentionCount += entry.mentionCount;
      if (guildEntryHasPlainUnread(
        hasUnread: entry.hasUnread,
        mentionCount: entry.mentionCount,
      )) {
        guildHasPlainUnread = true;
      }
    }
    return computeAppIconBadge(
      guildMentionCount: guildMentionCount,
      dmMentionCount: _dmMentionCount,
      pendingFriendRequestCount: pendingFriendRequestCount,
      guildHasPlainUnread: guildHasPlainUnread,
      dmHasPlainUnread: _dmHasPlainUnread,
    );
  }
}
