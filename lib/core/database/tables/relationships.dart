import 'package:drift/drift.dart';

class Relationships extends Table {
  TextColumn get userId => text()();
  IntColumn get type => integer()();
  TextColumn get nickname => text().nullable()();
  DateTimeColumn get since => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {userId};
}
