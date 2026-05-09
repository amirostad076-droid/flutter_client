import 'package:drift/drift.dart';

class FavoriteSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get collapsedCategoryIdsJson =>
      text().withDefault(const Constant('[]'))();
  BoolColumn get hideMuted => boolean().withDefault(const Constant(false))();
  BoolColumn get muted => boolean().withDefault(const Constant(false))();

  @override
  String get tableName => 'favorite_settings';

  @override
  Set<Column> get primaryKey => {id};
}
