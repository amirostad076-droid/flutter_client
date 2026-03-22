import 'package:drift/drift.dart';

import 'package:fluxeron/core/database/fluxer_database.dart';
import 'package:fluxeron/core/database/tables/channels.dart';

part 'channel_dao.g.dart';

@DriftAccessor(tables: [Channels])
class ChannelDao extends DatabaseAccessor<FluxerDatabase>
    with _$ChannelDaoMixin {
  ChannelDao(super.attachedDatabase);

  Stream<List<Channel>> watchChannels(String serverId) =>
      (select(channels)
            ..where((c) => c.serverId.equals(serverId))
            ..orderBy([(c) => OrderingTerm.asc(c.position)]))
          .watch();

  Future<List<Channel>> getChannels(String serverId) =>
      (select(channels)
            ..where((c) => c.serverId.equals(serverId))
            ..orderBy([(c) => OrderingTerm.asc(c.position)]))
          .get();

  Future<Channel?> getChannelById(String id) =>
      (select(channels)..where((c) => c.id.equals(id))).getSingleOrNull();

  Future<void> upsertChannel(ChannelsCompanion channel) =>
      into(channels).insertOnConflictUpdate(channel);

  Future<void> upsertChannels(List<ChannelsCompanion> channelList) async {
    await batch((b) {
      for (final channel in channelList) {
        b.insert(channels, channel, onConflict: DoUpdate((_) => channel));
      }
    });
  }

  Future<void> updateLastMessageId(String channelId, String messageId) =>
      (update(channels)..where((c) => c.id.equals(channelId))).write(
        ChannelsCompanion(lastMessageId: Value(messageId)),
      );

  Future<void> deleteChannel(String id) =>
      (delete(channels)..where((c) => c.id.equals(id))).go();

  Future<void> deleteChannelsForServer(String serverId) =>
      (delete(channels)..where((c) => c.serverId.equals(serverId))).go();

  Future<void> clearAll() => delete(channels).go();
}
