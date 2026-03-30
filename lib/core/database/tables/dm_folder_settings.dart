import 'package:drift/drift.dart';

class DmFolderSettingsTable extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();
  BoolColumn get collapseDms => boolean().withDefault(const Constant(false))();
  TextColumn get allowlistedIdsJson =>
      text().withDefault(const Constant('[]'))();

  @override
  Set<Column> get primaryKey => {id};
}
