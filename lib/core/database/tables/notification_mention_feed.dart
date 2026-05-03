import 'package:drift/drift.dart';

@TableIndex(name: 'idx_notification_mentions_ordinal', columns: {#ordinal})
class NotificationMentionFeed extends Table {
  TextColumn get messageId => text()();
  TextColumn get channelId => text()();
  IntColumn get ordinal => integer()();

  @override
  Set<Column> get primaryKey => {messageId};
}
