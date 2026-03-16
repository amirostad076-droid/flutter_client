import 'package:fluxeron/core/providers/database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'unread_provider.g.dart';

class UnreadState {
  final bool hasUnread;
  final int mentionCount;

  const UnreadState({
    this.hasUnread = false,
    this.mentionCount = 0,
  });
}

@riverpod
Stream<UnreadState> channelUnread(
  Ref ref,
  String channelId,
) async* {
  final db = ref.watch(fluxerDatabaseProvider);

  await for (final readState
      in db.readStateDao.watchReadState(channelId)) {
    if (readState == null || readState.lastMessageId == null) {
      yield const UnreadState();
      continue;
    }

    final messages =
        await db.messageDao.getMessages(channelId, limit: 1);
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
      hasUnread: hasUnread,
      mentionCount: readState.mentionCount,
    );
  }
}

@riverpod
Stream<UnreadState> serverUnread(
  Ref ref,
  String serverId,
) async* {
  final db = ref.watch(fluxerDatabaseProvider);

  await for (final channels
      in db.channelDao.watchChannels(serverId)) {
    var anyUnread = false;
    var totalMentions = 0;

    for (final channel in channels) {
      final readState =
          await db.readStateDao.getReadState(channel.id);

      if (readState == null || readState.lastMessageId == null) {
        continue;
      }

      totalMentions += readState.mentionCount;

      final messages =
          await db.messageDao.getMessages(channel.id, limit: 1);
      if (messages.isEmpty) {
        if (readState.mentionCount > 0) {
          anyUnread = true;
        }
        continue;
      }

      final latestMessageId = messages.last.id;
      if (latestMessageId != readState.lastMessageId) {
        anyUnread = true;
      }
    }

    yield UnreadState(
      hasUnread: anyUnread,
      mentionCount: totalMentions,
    );
  }
}
