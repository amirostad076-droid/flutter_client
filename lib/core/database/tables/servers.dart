import 'package:drift/drift.dart';

class Servers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get icon => text().nullable()();
  TextColumn get banner => text().nullable()();
  IntColumn get memberCount => integer().withDefault(const Constant(0))();
  IntColumn get onlineCount => integer().withDefault(const Constant(0))();
  TextColumn get description => text().nullable()();
  TextColumn get ownerId => text().nullable()();
  IntColumn get position => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
