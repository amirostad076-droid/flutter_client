import 'package:drift/drift.dart';

@TableIndex(name: 'idx_member_cache_access_guild', columns: {#guildId})
class MemberCacheAccess extends Table {
  TextColumn get userId => text()();
  TextColumn get guildId => text()();
  DateTimeColumn get lastAccessedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {userId, guildId};
}
