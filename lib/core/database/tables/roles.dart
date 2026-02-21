import 'package:drift/drift.dart';

@TableIndex(name: 'idx_roles_server', columns: {#serverId})
class Roles extends Table {
  TextColumn get id => text()();
  TextColumn get serverId => text()();
  TextColumn get name => text()();
  IntColumn get color => integer().withDefault(const Constant(0))();
  IntColumn get position => integer().withDefault(const Constant(0))();
  BoolColumn get isHoisted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
