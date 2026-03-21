import 'package:drift/drift.dart';

class FavoriteMemesTable extends Table {
  TextColumn get id => text()();
  TextColumn get data => text()();

  @override
  Set<Column> get primaryKey => {id};
}
