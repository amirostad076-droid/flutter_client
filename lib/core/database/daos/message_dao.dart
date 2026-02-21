import 'package:drift/drift.dart';

import 'package:fluxeron/core/database/fluxer_database.dart';
import 'package:fluxeron/core/database/tables/messages.dart';

part 'message_dao.g.dart';

@DriftAccessor(tables: [Messages])
class MessageDao extends DatabaseAccessor<FluxerDatabase>
    with _$MessageDaoMixin {
  MessageDao(super.attachedDatabase);

  Stream<List<Message>> watchMessages(String channelId) =>
      (select(messages)
            ..where((m) => m.channelId.equals(channelId))
            ..orderBy([(m) => OrderingTerm.asc(m.timestamp)]))
          .watch();

  Future<List<Message>> getMessages(
    String channelId, {
    int limit = 50,
    String? beforeId,
  }) async {
    final query = select(messages)
      ..where((m) => m.channelId.equals(channelId))
      ..orderBy([(m) => OrderingTerm.desc(m.timestamp)])
      ..limit(limit);

    if (beforeId != null) {
      final beforeMsg = await (select(
        messages,
      )..where((m) => m.id.equals(beforeId))).getSingleOrNull();
      if (beforeMsg != null) {
        query.where((m) => m.timestamp.isSmallerThanValue(beforeMsg.timestamp));
      }
    }

    final results = await query.get();
    return results.reversed.toList();
  }

  Future<void> upsertMessage(MessagesCompanion message) =>
      into(messages).insertOnConflictUpdate(message);

  Future<void> upsertMessages(List<MessagesCompanion> messageList) async {
    await batch((b) {
      for (final message in messageList) {
        b.insert(messages, message, onConflict: DoUpdate((_) => message));
      }
    });
  }

  Future<void> deleteMessage(String id) =>
      (delete(messages)..where((m) => m.id.equals(id))).go();

  Future<void> deleteMessagesForChannel(String channelId) =>
      (delete(messages)..where((m) => m.channelId.equals(channelId))).go();

  Future<void> clearAll() => delete(messages).go();
}
