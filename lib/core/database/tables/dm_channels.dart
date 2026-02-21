import 'package:drift/drift.dart';

class DmChannels extends Table {
  TextColumn get id => text()();
  TextColumn get recipientId => text()();
  TextColumn get lastMessage => text().withDefault(const Constant(''))();
  DateTimeColumn get lastMessageTime =>
      dateTime().withDefault(currentDateAndTime)();
  IntColumn get unreadCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
