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
      yield UnreadState(mentionCount: readState.mentionCount);
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
