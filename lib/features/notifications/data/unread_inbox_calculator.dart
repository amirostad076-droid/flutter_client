import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/features/channels/data/read_state_utils.dart';
import 'package:fluxer_app/features/channels/data/unread_settings_resolver.dart';
import 'package:fluxer_app/features/notifications/domain/unread_inbox_entry.dart';
import 'package:fluxer_app/shared/utils/snowflake_time.dart';
import 'package:fluxer_dart/export.dart';

const int _voiceType = 2;
const int _categoryType = 4;
const Duration _oldMessageThreshold = Duration(days: 7);
const Duration _recentVisitThreshold = Duration(days: 3);
final BigInt _zero = BigInt.zero;

int snowflakeComparator(String? id) {
  if (id == null || id.isEmpty) {
    return 0;
  }
  final parsed = int.tryParse(id);
  if (parsed == null) {
    return 0;
  }
  final ms = (parsed >> 22) + kSnowflakeEpochMs;
  return ms.clamp(0, 1 << 30);
}

int _contentTimestampMs(String? snowflakeId) {
  if (snowflakeId == null || snowflakeId.isEmpty) {
    return 0;
  }
  final DateTime? utc = dateTimeFromUserSnowflakeOrNull(snowflakeId);
  return utc?.millisecondsSinceEpoch ?? 0;
}

int _compareBigIntSnowflakesDesc(String a, String b) {
  final ai = BigInt.tryParse(a) ?? _zero;
  final bi = BigInt.tryParse(b) ?? _zero;
  return bi.compareTo(ai);
}

bool _hasGuildUnreadByWebRules({
  required String? channelLastMessageId,
  required String? ackLastMessageId,
  required int fallbackAckMs,
  required int mentionCount,
}) {
  if (mentionCount > 0) {
    return true;
  }
  final String lastSf = channelLastMessageId ?? '';
  final String ackSf = ackLastMessageId ?? '';
  if (lastSf.isNotEmpty && ackSf.isNotEmpty) {
    return _compareBigIntSnowflakesDesc(lastSf, ackSf) > 0;
  }
  final int contentMs = _contentTimestampMs(channelLastMessageId);
  final int ackMs = ackSf.isNotEmpty
      ? _contentTimestampMs(ackLastMessageId)
      : fallbackAckMs;
  if (contentMs == 0 || ackMs == 0) {
    return false;
  }
  return contentMs > ackMs;
}

class UnreadInboxCalculator {
  const UnreadInboxCalculator._();

  static Future<List<UnreadInboxEntry>> compute(
    FluxerDatabase db, {
    required Map<String, bool> collapsedByChannelId,
    String? currentUserId,
  }) async {
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    final List<UnreadInboxEntry> entries = <UnreadInboxEntry>[];

    final List<Channel> allChannels = await db.channelDao.getAllChannels();
    final List<ReadState> readStatesList = await db.readStateDao
        .watchReadStates()
        .first;
    final Map<String, ReadState> readStateMap = <String, ReadState>{
      for (final ReadState r in readStatesList) r.channelId: r,
    };
    final List<UserGuildSettingsTableData> userGuildRows = await db
        .userGuildSettingsDao
        .getAll();

    final Map<String, int> joinTimeMsByGuildId = <String, int>{};
    Future<int> resolveFallbackAckMs(String guildId, String channelId) async {
      if (joinTimeMsByGuildId.containsKey(guildId)) {
        return joinTimeMsByGuildId[guildId]!;
      }
      int resolved = 0;
      if (currentUserId != null && currentUserId.isNotEmpty) {
        final Member? member = await db.memberDao.getMemberByUserId(
          currentUserId,
          guildId,
        );
        final DateTime? joinedAt = member?.joinedAt;
        if (joinedAt != null) {
          resolved = joinedAt.millisecondsSinceEpoch;
        }
      }
      if (resolved == 0) {
        final DateTime? chTime = dateTimeFromUserSnowflakeOrNull(channelId);
        resolved = chTime?.millisecondsSinceEpoch ?? 0;
      }
      joinTimeMsByGuildId[guildId] = resolved;
      return resolved;
    }

    final Map<String, UserGuildSettingsResponse> guildSettingsByGuild =
        <String, UserGuildSettingsResponse>{};

    for (final UserGuildSettingsTableData row in userGuildRows) {
      final settings = decodeUserGuildSettings(row.data);
      if (settings != null) {
        guildSettingsByGuild[row.guildId] = settings;
      }
    }

    for (final Channel channel in allChannels) {
      if (channel.type == _categoryType) {
        continue;
      }
      final String guildId = channel.guildId;
      final ReadState? readState = readStateMap[channel.id];
      final int mentions = readState?.mentionCount ?? 0;
      final bool isVoice = channel.type == _voiceType;
      final unreadSettings = resolveUnreadSettings(
        channel: channel,
        guildSettings: guildSettingsByGuild[guildId],
        now: DateTime.fromMillisecondsSinceEpoch(nowMs),
      );

      if (isVoice && mentions == 0) {
        continue;
      }

      if (unreadSettings.isMuted && mentions == 0) {
        continue;
      }

      final String? channelLastMsg = channel.lastMessageId;
      final String? ackId = readState?.lastMessageId;
      final int lastMsgMsForStale = _contentTimestampMs(channelLastMsg);

      if (lastMsgMsForStale > 0 &&
          lastMsgMsForStale < nowMs - _oldMessageThreshold.inMilliseconds) {
        final int ackMsForStale = ackId != null && ackId.isNotEmpty
            ? _contentTimestampMs(ackId)
            : await resolveFallbackAckMs(guildId, channel.id);
        final bool recentlyVisited =
            ackMsForStale > nowMs - _recentVisitThreshold.inMilliseconds;
        if (!recentlyVisited && mentions == 0) {
          continue;
        }
      }

      final int tsLast = snowflakeComparator(channelLastMsg);
      final int fallbackAckMs = await resolveFallbackAckMs(guildId, channel.id);
      final bool hasUnreadMessage = _hasGuildUnreadByWebRules(
        channelLastMessageId: channelLastMsg,
        ackLastMessageId: ackId,
        fallbackAckMs: fallbackAckMs,
        mentionCount: 0,
      );
      final bool hasUnread =
          mentions > 0 ||
          (unreadSettings.allowsMessageUnread && hasUnreadMessage);

      if (!hasUnread) {
        continue;
      }

      final int recency = tsLast != 0 ? tsLast : snowflakeComparator(ackId);

      entries.add(
        UnreadInboxEntry(
          channelId: channel.id,
          guildId: guildId,
          isDm: false,
          mentionCount: mentions,
          isCollapsed: collapsedByChannelId[channel.id] ?? false,
          recencyComparator: recency.clamp(0, 1 << 30),
        ),
      );
    }

    final List<DmChannel> dms = await db.dmChannelDao.getDmChannels();
    final dmLastMessages = await db.messageDao.getLastMessageForChannels(
      dms.map((dm) => dm.id).toList(),
    );
    for (final DmChannel dm in dms) {
      final readState = readStateMap[dm.id];
      final unreadCount = dmUnreadCountFromReadState(
        hasReadState: readState != null,
        latestMessageId: dmLastMessages[dm.id]?.id,
        ackLastMessageId: readState?.lastMessageId,
        mentionCount: readState?.mentionCount ?? 0,
        cachedUnreadCount: dm.unreadCount,
      );
      if (unreadCount <= 0) {
        continue;
      }
      final int ms =
          dmLastMessages[dm.id]?.timestamp.millisecondsSinceEpoch ??
          dm.lastMessageTime.millisecondsSinceEpoch;
      entries.add(
        UnreadInboxEntry(
          channelId: dm.id,
          guildId: null,
          isDm: true,
          mentionCount: unreadCount,
          isCollapsed: collapsedByChannelId[dm.id] ?? false,
          recencyComparator: ms.clamp(0, 1 << 30),
        ),
      );
    }

    entries.sort((UnreadInboxEntry a, UnreadInboxEntry b) {
      final int byRecency = b.recencyComparator.compareTo(a.recencyComparator);
      if (byRecency != 0) {
        return byRecency;
      }
      return _compareBigIntSnowflakesDesc(a.channelId, b.channelId);
    });

    return entries;
  }
}
