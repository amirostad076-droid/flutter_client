import 'package:drift/drift.dart';

import 'package:fluxeron/core/database/fluxer_database.dart';
import 'package:fluxeron/core/database/tables/roles.dart';

part 'role_dao.g.dart';

@DriftAccessor(tables: [Roles])
class RoleDao extends DatabaseAccessor<FluxerDatabase> with _$RoleDaoMixin {
  RoleDao(super.attachedDatabase);

  Future<List<Role>> getRoles(String serverId) =>
      (select(roles)
            ..where((r) => r.serverId.equals(serverId))
            ..orderBy([(r) => OrderingTerm.desc(r.position)]))
          .get();

  Stream<List<Role>> watchRoles(String serverId) =>
      (select(roles)
            ..where((r) => r.serverId.equals(serverId))
            ..orderBy([(r) => OrderingTerm.desc(r.position)]))
          .watch();

  Future<Role?> getRoleById(String id) =>
      (select(roles)..where((r) => r.id.equals(id))).getSingleOrNull();

  Future<void> upsertRoles(List<RolesCompanion> roleList) async {
    await batch((b) {
      for (final role in roleList) {
        b.insert(roles, role, onConflict: DoUpdate((_) => role));
      }
    });
  }

  Future<void> deleteRole(String id) =>
      (delete(roles)..where((r) => r.id.equals(id))).go();

  Future<void> deleteRolesForServer(String serverId) =>
      (delete(roles)..where((r) => r.serverId.equals(serverId))).go();

  Future<void> clearAll() => delete(roles).go();
}
