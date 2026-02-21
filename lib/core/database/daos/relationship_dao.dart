import 'package:drift/drift.dart';

import 'package:fluxeron/core/database/fluxer_database.dart';
import 'package:fluxeron/core/database/tables/relationships.dart';

part 'relationship_dao.g.dart';

@DriftAccessor(tables: [Relationships])
class RelationshipDao extends DatabaseAccessor<FluxerDatabase>
    with _$RelationshipDaoMixin {
  RelationshipDao(super.attachedDatabase);

  Future<List<Relationship>> getRelationships() => select(relationships).get();

  Stream<List<Relationship>> watchRelationships() =>
      select(relationships).watch();

  Future<void> upsertRelationships(
    List<RelationshipsCompanion> relationshipList,
  ) async {
    await batch((b) {
      for (final rel in relationshipList) {
        b.insert(relationships, rel, onConflict: DoUpdate((_) => rel));
      }
    });
  }

  Future<void> deleteRelationship(String userId) =>
      (delete(relationships)..where((r) => r.userId.equals(userId))).go();

  Future<void> clearAll() => delete(relationships).go();
}
