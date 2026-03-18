import 'package:drift/drift.dart';
import 'package:fluxeron/core/database/fluxer_database.dart';
import 'package:fluxeron/core/database/tables/guild_last_channels.dart';

part 'guild_last_channel_dao.g.dart';

@DriftAccessor(tables: [GuildLastChannels])
class GuildLastChannelDao extends DatabaseAccessor<FluxerDatabase>
    with _$GuildLastChannelDaoMixin {
  GuildLastChannelDao(super.attachedDatabase);

  Future<String?> getLastChannel(String guildId) async {
    final row = await (select(
      guildLastChannels,
    )..where((t) => t.guildId.equals(guildId))).getSingleOrNull();
    return row?.channelId;
  }

  Future<void> setLastChannel(String guildId, String channelId) {
    return into(guildLastChannels).insertOnConflictUpdate(
      GuildLastChannelsCompanion.insert(guildId: guildId, channelId: channelId),
    );
  }

  Future<void> removeGuild(String guildId) {
    return (delete(
      guildLastChannels,
    )..where((t) => t.guildId.equals(guildId))).go();
  }

  Future<void> clearAll() {
    return delete(guildLastChannels).go();
  }
}
