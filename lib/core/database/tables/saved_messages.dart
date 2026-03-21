import 'package:drift/drift.dart';

class SavedMessages extends Table {
  TextColumn get messageId => text()();

  @override
  Set<Column> get primaryKey => {messageId};
}
