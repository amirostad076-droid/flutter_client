import 'package:drift/drift.dart';

class EmojiUsage extends Table {
  TextColumn get key => text()();
  IntColumn get useCount =>
      integer().withDefault(const Constant(1))();
  DateTimeColumn get lastUsed => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}
