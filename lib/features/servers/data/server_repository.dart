import 'package:dio/dio.dart';
import 'package:fluxer_dart/fluxer_dart.dart';

import 'package:fluxeron/core/database/fluxer_database.dart' as db;
import 'package:fluxeron/features/servers/domain/server.dart';
import 'package:fluxeron/shared/utils/sdk_converters.dart';

class ServerRepository {
  final FluxerDart _client;
  final db.FluxerDatabase _db;

  const ServerRepository(this._client, this._db);

  Stream<List<Server>> watchServers() {
    return _db.serverDao.watchServers().map(
      (rows) => rows.map(Server.fromRow).toList(),
    );
  }

  Future<List<Server>> getServers() async {
    try {
      final response = await _client.getGuildsApi().listGuilds();
      final data = response.data;
      if (data == null) {
        return [];
      }

      // Fetch user settings to get guild folder ordering.
      final guildOrder = await _fetchGuildOrder();

      final companions = data.map((guild) {
        final position = guildOrder.indexOf(guild.id);
        return serverFromSdk(
          guild,
          position: position >= 0 ? position : guildOrder.length,
        );
      }).toList();
      await _db.serverDao.upsertServers(companions);

      final rows = await _db.serverDao.getServers();
      return rows.map(Server.fromRow).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.statusMessage ?? 'Failed to fetch servers');
    }
  }

  /// Fetches ordered guild IDs from user settings guild folders.
  Future<List<String>> _fetchGuildOrder() async {
    try {
      final settings =
          await _client.getUsersApi().getCurrentUserSettings();
      final folders = settings.data?.guildFolders;
      if (folders == null) {
        return [];
      }
      return folders.expand((f) => f.guildIds).toList();
    } on Object {
      return [];
    }
  }

  Future<Server> getServer(String guildId) async {
    try {
      final response = await _client.getGuildsApi().getGuild(guildId: guildId);
      final data = response.data;
      if (data == null) {
        throw Exception('Empty response from getGuild');
      }

      await _db.serverDao.upsertServer(serverFromSdk(data));

      final row = await _db.serverDao.getServerById(guildId);
      if (row == null) {
        throw Exception('Server not found after upsert');
      }
      return Server.fromRow(row);
    } on DioException catch (e) {
      throw Exception(e.response?.statusMessage ?? 'Failed to fetch server');
    }
  }
}
