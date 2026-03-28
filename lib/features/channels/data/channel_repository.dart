import 'package:dio/dio.dart';
import 'package:fluxer_dart/export.dart';

import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/features/channels/domain/channel.dart';
import 'package:fluxer_app/shared/utils/sdk_converters.dart';

class ChannelRepository {
  final FluxerClient _client;
  final db.FluxerDatabase _db;

  const ChannelRepository(this._client, this._db);

  Stream<List<Channel>> watchChannels(String serverId) {
    return _db.channelDao
        .watchChannels(serverId)
        .map((rows) => rows.map(Channel.fromRow).toList());
  }

  Future<List<ChannelCategory>> getChannels(String serverId) async {
    try {
      final channels = await _client.guilds.listGuildChannels(
        guildId: serverId,
      );

      final companions = channels
          .map((ch) => channelFromSdk(ch, serverId))
          .toList();
      await _db.channelDao.upsertChannels(companions);

      final rows = await _db.channelDao.getChannels(serverId);
      final channelList = rows.map(Channel.fromRow).toList();
      return groupChannelsIntoCategories(channelList);
    } on DioException catch (e) {
      throw Exception(e.response?.statusMessage ?? 'Failed to fetch channels');
    }
  }
}
