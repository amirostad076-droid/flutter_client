import 'package:drift/drift.dart';

class UserNotesTable extends Table {
  TextColumn get targetUserId => text()();
  TextColumn get content => text()();

  @override
  Set<Column> get primaryKey => {targetUserId};
}
