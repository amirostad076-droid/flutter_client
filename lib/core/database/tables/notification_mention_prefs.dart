import 'package:drift/drift.dart';

class NotificationMentionPrefs extends Table {
  IntColumn get id => integer()();
  BoolColumn get includeEveryone =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get includeRoles => boolean().withDefault(const Constant(true))();
  BoolColumn get includeGuilds => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
