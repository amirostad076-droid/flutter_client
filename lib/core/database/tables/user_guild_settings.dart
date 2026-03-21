import 'package:drift/drift.dart';

class UserGuildSettingsTable extends Table {
  TextColumn get guildId => text()();
  TextColumn get data => text()();

  @override
  Set<Column> get primaryKey => {guildId};
}
