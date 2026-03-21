import 'package:drift/drift.dart';

class ReadStates extends Table {
  TextColumn get channelId => text()();
  TextColumn get lastMessageId => text().nullable()();
  IntColumn get mentionCount => integer().withDefault(const Constant(0))();
  TextColumn get lastPinTimestamp => text().nullable()();

  @override
  Set<Column> get primaryKey => {channelId};
}
