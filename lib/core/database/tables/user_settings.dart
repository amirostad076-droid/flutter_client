import 'package:drift/drift.dart';

class UserSettingsTable extends Table {
  TextColumn get userId => text()();
  TextColumn get data => text()();

  @override
  Set<Column> get primaryKey => {userId};
}
