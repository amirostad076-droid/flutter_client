import 'package:drift/drift.dart';

class DmChannels extends Table {
  TextColumn get id => text()();
  IntColumn get type => integer().withDefault(const Constant(1))();
  TextColumn get recipientId => text()();
  TextColumn get name => text().nullable()();
  IntColumn get recipientCount => integer().withDefault(const Constant(2))();
  TextColumn get lastMessage => text().withDefault(const Constant(''))();
  DateTimeColumn get lastMessageTime =>
      dateTime().withDefault(currentDateAndTime)();
  IntColumn get unreadCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
