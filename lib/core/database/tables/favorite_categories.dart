import 'package:drift/drift.dart';

class FavoriteCategories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get position => integer().withDefault(const Constant(0))();

  @override
  String get tableName => 'favorite_categories';

  @override
  Set<Column> get primaryKey => {id};
}
