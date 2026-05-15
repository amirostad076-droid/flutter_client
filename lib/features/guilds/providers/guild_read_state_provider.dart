import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/features/channels/data/read_state_utils.dart';
import 'package:fluxer_app/features/channels/data/unread_permission_utils.dart';
import 'package:fluxer_app/features/channels/data/unread_settings_resolver.dart';
import 'package:fluxer_dart/export.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'guild_read_state_provider.g.dart';

const int _voiceType = 2;
const int _categoryType = 4;

@immutable
class GuildReadStateEntry {
  const GuildReadStateEntry({
    required this.hasUnread,
    required this.mentionCount,
    required this.mentionChannels,
    required this.unreadChannelId,
    required this.sentinel,
  });

  static const GuildReadStateEntry empty = GuildReadStateEntry(
    hasUnread: false,
    mentionCount: 0,
    mentionChannels: <String>{},
    unreadChannelId: null,
    sentinel: 0,
  );

  final bool hasUnread;
  final int mentionCount;
  final Set<String> mentionChannels;
  final String? unreadChannelId;
  final int sentinel;

  bool hasSameFields(GuildReadStateEntry other) {
    if (hasUnread != other.hasUnread) {
      return false;
    }
    if (mentionCount != other.mentionCount) {
      return false;
    }
    if (unreadChannelId != other.unreadChannelId) {
      return false;
    }
    if (mentionChannels.length != other.mentionChannels.length) {
      return false;
    }
    return mentionChannels.containsAll(other.mentionChannels);
  }

  GuildReadStateEntry copyWith({
    bool? hasUnread,
    int? mentionCount,
    Set<String>? mentionChannels,
    Object? unreadChannelId = _sentinel,
    int? sentinel,
  }) => GuildReadStateEntry(
    hasUnread: hasUnread ?? this.hasUnread,
    mentionCount: mentionCount ?? this.mentionCount,
    mentionChannels: mentionChannels ?? this.mentionChannels,
    unreadChannelId: identical(unreadChannelId, _sentinel)
        ? this.unreadChannelId
        : unreadChannelId as String?,
    sentinel: sentinel ?? this.sentinel,
  );
}

const Object _sentinel = Object();

@Riverpod(keepAlive: true)
class GuildReadState extends _$GuildReadState {
  Map<String, ReadState> _readStateSnapshot = <String, ReadState>{};
  Map<String, Channel> _channelSnapshot = <String, Channel>{};
  bool _seeded = false;
  Future<void>? _pendingRecompute;
  final Set<String> _queuedGuildIds = <String>{};

  @override
  Map<String, GuildReadStateEntry> build() {
    final db = ref.watch(fluxerDatabaseProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    final readStateSub = db.readStateDao.watchReadStates().listen((rows) {
      final next = <String, ReadState>{
        for (final r in rows) r.channelId: r,
      };
      final touched = _diffReadStates(_readStateSnapshot, next);
      _readStateSnapshot = next;
      if (touched.isNotEmpty) {
        _queueChannelIds(touched, db, currentUserId);
      }
    });

    final channelSub = db.channelDao.watchAllChannels().listen((channels) {
      final next = <String, Channel>{for (final c in channels) c.id: c};
      final touched = _diffChannels(_channelSnapshot, next);
      _channelSnapshot = next;
      if (touched.isNotEmpty) {
        _queueChannelIds(touched, db, currentUserId);
      }
    });

    final settingsSub = db.userGuildSettingsDao.watchAll().listen((rows) {
      final guildIds = rows.map((s) => s.guildId).toSet();
      _queueGuildIds(guildIds, db, currentUserId);
    });

    final guildSub = db.guildDao.watchServers().listen((guilds) {
      _queueGuildIds(guilds.map((g) => g.id).toSet(), db, currentUserId);
    });

    ref.listen<bool>(gatewayReadyProvider, (prev, next) {
      if (!(prev ?? false) && next) {
        _seeded = false;
        unawaited(_seedAll(db, currentUserId));
      }
    });

    if (ref.read(gatewayReadyProvider)) {
      unawaited(_seedAll(db, currentUserId));
    }

    ref.onDispose(() {
      unawaited(readStateSub.cancel());
      unawaited(channelSub.cancel());
      unawaited(settingsSub.cancel());
      unawaited(guildSub.cancel());
    });

    return <String, GuildReadStateEntry>{};
  }

  GuildReadStateEntry entryFor(String guildId) =>
      state[guildId] ?? GuildReadStateEntry.empty;

  Future<void> _seedAll(FluxerDatabase db, String? currentUserId) async {
    if (_seeded) {
      return;
    }
    _seeded = true;
    final guilds = await db.guildDao.getServers();
    final allChannels = await db.channelDao.getAllChannels();
    final allReadStates = await db.readStateDao.getReadStates();
    _channelSnapshot = {for (final c in allChannels) c.id: c};
    _readStateSnapshot = {for (final r in allReadStates) r.channelId: r};
    await _recomputeGuilds(
      guilds.map((g) => g.id).toSet(),
      db,
      currentUserId,
    );
  }

  void _queueChannelIds(
    Set<String> channelIds,
    FluxerDatabase db,
    String? currentUserId,
  ) {
    final guildIds = <String>{};
    for (final channelId in channelIds) {
      final channel = _channelSnapshot[channelId];
      if (channel != null) {
        guildIds.add(channel.guildId);
      }
    }
    if (guildIds.isNotEmpty) {
      _queueGuildIds(guildIds, db, currentUserId);
    }
  }

  void _queueGuildIds(
    Set<String> guildIds,
    FluxerDatabase db,
    String? currentUserId,
  ) {
    if (guildIds.isEmpty) {
      return;
    }
    _queuedGuildIds.addAll(guildIds);
    _pendingRecompute ??= Future.microtask(() async {
      final drained = Set<String>.from(_queuedGuildIds);
      _queuedGuildIds.clear();
      _pendingRecompute = null;
      await _recomputeGuilds(drained, db, currentUserId);
    });
  }

  Future<void> _recomputeGuilds(
    Set<String> guildIds,
    FluxerDatabase db,
    String? currentUserId,
  ) async {
    if (guildIds.isEmpty) {
      return;
    }
    final next = Map<String, GuildReadStateEntry>.from(state);
    var mutated = false;
    for (final guildId in guildIds) {
      final entry = await _computeGuildEntry(guildId, db, currentUserId);
      final existing = next[guildId];
      if (existing == null || !entry.hasSameFields(existing)) {
        next[guildId] = entry.copyWith(
          sentinel: (existing?.sentinel ?? 0) + 1,
        );
        mutated = true;
      }
    }
    if (mutated) {
      state = next;
    }
  }

  Future<GuildReadStateEntry> _computeGuildEntry(
    String guildId,
    FluxerDatabase db,
    String? currentUserId,
  ) async {
    final channels = await db.channelDao.getChannels(guildId);
    if (channels.isEmpty) {
      return GuildReadStateEntry.empty;
    }

    final guildSettingsRow = await db.userGuildSettingsDao.getByGuildId(
      guildId,
    );
    final guildSettings = guildSettingsRow == null
        ? null
        : decodeUserGuildSettings(guildSettingsRow.data);

    final now = DateTime.now();
    var anyUnread = false;
    var totalMentions = 0;
    String? firstUnreadChannelId;
    final mentionChannels = <String>{};

    for (final channel in channels) {
      if (channel.type == _categoryType) {
        continue;
      }

      if (!await canReadChannelForUnread(
        database: db,
        channel: channel,
        currentUserId: currentUserId,
      )) {
        continue;
      }

      final readState = _readStateSnapshot[channel.id];
      final contribution = await _computeChannelContribution(
        channel: channel,
        readState: readState,
        guildSettings: guildSettings,
        now: now,
        db: db,
        currentUserId: currentUserId,
      );

      if (contribution.mentions > 0) {
        mentionChannels.add(channel.id);
        totalMentions += contribution.mentions;
      }

      if (contribution.unreadEligible) {
        anyUnread = true;
        firstUnreadChannelId ??= channel.id;
      }
    }

    return GuildReadStateEntry(
      hasUnread: anyUnread || totalMentions > 0,
      mentionCount: totalMentions,
      mentionChannels: mentionChannels,
      unreadChannelId: firstUnreadChannelId,
      sentinel: 0,
    );
  }

  Future<_Contribution> _computeChannelContribution({
    required Channel channel,
    required ReadState? readState,
    required UserGuildSettingsResponse? guildSettings,
    required DateTime now,
    required FluxerDatabase db,
    required String? currentUserId,
  }) async {
    final isVoice = channel.type == _voiceType;
    final rawMentions = readState?.mentionCount ?? 0;
    final visibleMentions =
        canShowMentionCount(
          channelLastMessageId: channel.lastMessageId,
          isGuildChannel: true,
          now: now,
        )
        ? rawMentions
        : 0;

    final unreadSettings = resolveUnreadSettings(
      channel: channel,
      guildSettings: guildSettings,
      now: now,
    );
    final mentions = unreadSettings.allowsMentionUnread ? visibleMentions : 0;

    if (isVoice) {
      return _Contribution(unreadEligible: false, mentions: mentions);
    }

    if (!unreadSettings.allowsGuildMessageUnread && mentions == 0) {
      return const _Contribution(unreadEligible: false, mentions: 0);
    }

    final fallbackAckMs = await guildChannelFallbackAckMs(
      database: db,
      channel: channel,
      currentUserId: currentUserId,
    );
    final staleSuppressed = shouldSuppressStaleUnread(
      channelLastMessageId: channel.lastMessageId,
      ackLastMessageId: readState?.lastMessageId,
      fallbackAckMs: fallbackAckMs,
      mentionCount: mentions,
      now: now,
    );
    if (staleSuppressed) {
      return _Contribution(unreadEligible: false, mentions: mentions);
    }

    final hasUnreadMessage = hasUnreadByReadState(
      channelLastMessageId: channel.lastMessageId,
      ackLastMessageId: readState?.lastMessageId,
      fallbackAckMs: fallbackAckMs,
      mentionCount: 0,
    );
    final eligible =
        mentions > 0 ||
        (unreadSettings.allowsGuildMessageUnread && hasUnreadMessage);

    return _Contribution(unreadEligible: eligible, mentions: mentions);
  }
}

Set<String> _diffReadStates(
  Map<String, ReadState> previous,
  Map<String, ReadState> next,
) {
  final changed = <String>{};
  for (final entry in next.entries) {
    final old = previous[entry.key];
    if (old == null || !_readStateEquals(old, entry.value)) {
      changed.add(entry.key);
    }
  }
  for (final oldKey in previous.keys) {
    if (!next.containsKey(oldKey)) {
      changed.add(oldKey);
    }
  }
  return changed;
}

bool _readStateEquals(ReadState a, ReadState b) =>
    a.lastMessageId == b.lastMessageId &&
    a.mentionCount == b.mentionCount &&
    a.lastPinTimestamp == b.lastPinTimestamp &&
    a.manual == b.manual &&
    a.stickyUnreadMessageId == b.stickyUnreadMessageId;

Set<String> _diffChannels(
  Map<String, Channel> previous,
  Map<String, Channel> next,
) {
  final changed = <String>{};
  for (final entry in next.entries) {
    final old = previous[entry.key];
    if (old == null || !_channelEquals(old, entry.value)) {
      changed.add(entry.key);
    }
  }
  for (final oldKey in previous.keys) {
    if (!next.containsKey(oldKey)) {
      changed.add(oldKey);
    }
  }
  return changed;
}

bool _channelEquals(Channel a, Channel b) =>
    a.guildId == b.guildId &&
    a.lastMessageId == b.lastMessageId &&
    a.lastPinTimestamp == b.lastPinTimestamp &&
    a.type == b.type &&
    a.parentId == b.parentId;

class _Contribution {
  const _Contribution({required this.unreadEligible, required this.mentions});

  final bool unreadEligible;
  final int mentions;
}
