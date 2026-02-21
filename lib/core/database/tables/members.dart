import 'package:drift/drift.dart';

@TableIndex(name: 'idx_members_server', columns: {#serverId})
class Members extends Table {
  TextColumn get userId => text()();
  TextColumn get serverId => text()();
  TextColumn get nickname => text().nullable()();
  TextColumn get serverAvatar => text().nullable()();
  TextColumn get roleIdsJson => text().withDefault(const Constant('[]'))();
  DateTimeColumn get joinedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {userId, serverId};
}
