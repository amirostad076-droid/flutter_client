import 'package:drift/drift.dart';

class AuthSessions extends Table {
  TextColumn get token => text()();
  TextColumn get userId => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {userId};
}
