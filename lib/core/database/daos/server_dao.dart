import 'package:drift/drift.dart';

import 'package:fluxeron/core/database/fluxer_database.dart';
import 'package:fluxeron/core/database/tables/servers.dart';

part 'server_dao.g.dart';

@DriftAccessor(tables: [Servers])
class ServerDao extends DatabaseAccessor<FluxerDatabase> with _$ServerDaoMixin {
  ServerDao(super.attachedDatabase);

  Stream<List<Server>> watchServers() =>
      (select(servers)..orderBy([(s) => OrderingTerm.asc(s.position)])).watch();

  Future<List<Server>> getServers() =>
      (select(servers)..orderBy([(s) => OrderingTerm.asc(s.position)])).get();

  Future<Server?> getServerById(String id) =>
      (select(servers)..where((s) => s.id.equals(id))).getSingleOrNull();

  Future<void> upsertServer(ServersCompanion server) =>
      into(servers).insertOnConflictUpdate(server);

  Future<void> upsertServers(List<ServersCompanion> serverList) async {
    await batch((b) {
      for (final server in serverList) {
        b.insert(servers, server, onConflict: DoUpdate((_) => server));
      }
    });
  }

  Future<void> clearAll() => delete(servers).go();
}
