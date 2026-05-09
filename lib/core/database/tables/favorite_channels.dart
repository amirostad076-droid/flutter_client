import 'package:drift/drift.dart';

@TableIndex(name: 'idx_favorite_channels_parent', columns: {#parentId})
class FavoriteChannels extends Table {
  TextColumn get channelId => text()();
  TextColumn get guildId => text().nullable()();
  TextColumn get parentId => text().nullable()();
  IntColumn get position => integer().withDefault(const Constant(0))();
  TextColumn get nickname => text().nullable()();

  @override
  String get tableName => 'favorite_channels';

  @override
  Set<Column> get primaryKey => {channelId};
}
