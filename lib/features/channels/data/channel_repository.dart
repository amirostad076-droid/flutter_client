import 'package:dio/dio.dart';
import 'package:fluxer_dart/fluxer_dart.dart';

import 'package:fluxeron/core/database/fluxer_database.dart' as db;
import 'package:fluxeron/features/channels/domain/channel.dart';
import 'package:fluxeron/shared/utils/sdk_converters.dart';

class ChannelRepository {
  final FluxerDart _client;
  final db.FluxerDatabase _db;

  const ChannelRepository(this._client, this._db);

  Stream<List<Channel>> watchChannels(String serverId) {
    return _db.channelDao
        .watchChannels(serverId)
        .map((rows) => rows.map(Channel.fromRow).toList());
  }

  Future<List<ChannelCategory>> getChannels(String serverId) async {
    try {
      final response = await _client.getGuildsApi().listGuildChannels(
        guildId: serverId,
      );
      final data = response.data;
      if (data == null) {
        return [];
      }

      final companions = data
          .map((ch) => channelFromSdk(ch, serverId))
          .toList();
      await _db.channelDao.upsertChannels(companions);

      final rows = await _db.channelDao.getChannels(serverId);
      final channels = rows.map(Channel.fromRow).toList();
      return groupChannelsIntoCategories(channels);
    } on DioException catch (e) {
      throw Exception(e.response?.statusMessage ?? 'Failed to fetch channels');
    }
  }
}
