import 'package:drift/drift.dart';
import 'package:fluxeron/core/database/fluxer_database.dart';
import 'package:fluxeron/core/database/tables/favorite_memes.dart';

part 'favorite_memes_dao.g.dart';

@DriftAccessor(tables: [FavoriteMemesTable])
class FavoriteMemesDao extends DatabaseAccessor<FluxerDatabase>
    with _$FavoriteMemesDaoMixin {
  FavoriteMemesDao(super.attachedDatabase);

  Future<List<FavoriteMemesTableData>> getAll() =>
      select(favoriteMemesTable).get();

  Stream<List<FavoriteMemesTableData>> watchAll() =>
      select(favoriteMemesTable).watch();

  Future<void> upsert(FavoriteMemesTableCompanion entry) =>
      into(favoriteMemesTable).insertOnConflictUpdate(entry);

  Future<void> deleteMeme(String id) =>
      (delete(favoriteMemesTable)..where((t) => t.id.equals(id))).go();

  Future<void> clearAll() => delete(favoriteMemesTable).go();
}
