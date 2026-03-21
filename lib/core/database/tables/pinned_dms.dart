import 'package:drift/drift.dart';

class PinnedDmsTable extends Table {
  TextColumn get channelId => text()();
  IntColumn get position => integer()();

  @override
  Set<Column> get primaryKey => {channelId};
}
