import 'package:drift/drift.dart';

import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/database/tables/channels.dart';

part 'channel_dao.g.dart';

@DriftAccessor(tables: [Channels])
class ChannelDao extends DatabaseAccessor<FluxerDatabase>
    with _$ChannelDaoMixin {
  ChannelDao(super.attachedDatabase);

  Stream<List<Channel>> watchChannels(String guildId) =>
      (select(channels)
            ..where((c) => c.guildId.equals(guildId))
            ..orderBy([(c) => OrderingTerm.asc(c.position)]))
          .watch();

  Stream<List<Channel>> watchAllChannels() => select(channels).watch();

  Future<List<Channel>> getAllChannels() => select(channels).get();

  Future<List<Channel>> getChannels(String guildId) =>
      (select(channels)
            ..where((c) => c.guildId.equals(guildId))
            ..orderBy([(c) => OrderingTerm.asc(c.position)]))
          .get();

  Future<Channel?> getChannelById(String id) =>
      (select(channels)..where((c) => c.id.equals(id))).getSingleOrNull();

  /// Root category (or channel without parent) first, then each child down to [channelId].
  Future<List<String?>> getPermissionOverwriteLayersRootToLeaf(
    String channelId,
  ) async {
    final List<Channel> bottomUp = <Channel>[];
    String? currentId = channelId;
    while (currentId != null) {
      final Channel? row = await getChannelById(currentId);
      if (row == null) {
        break;
      }
      bottomUp.add(row);
      currentId = row.parentId;
    }
    return <String?>[
      for (final Channel row in bottomUp.reversed)
        row.permissionOverwritesJson,
    ];
  }

  Stream<Channel?> watchChannelById(String id) =>
      (select(channels)..where((c) => c.id.equals(id))).watchSingleOrNull();

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

  Future<void> deleteChannelsForGuild(String guildId) =>
      (delete(channels)..where((c) => c.guildId.equals(guildId))).go();

  Future<void> clearAll() => delete(channels).go();
}
