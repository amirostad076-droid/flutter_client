import 'package:drift/drift.dart';

import 'package:fluxeron/core/database/fluxer_database.dart';
import 'package:fluxeron/core/database/tables/dm_channels.dart';

part 'dm_channel_dao.g.dart';

@DriftAccessor(tables: [DmChannels])
class DmChannelDao extends DatabaseAccessor<FluxerDatabase>
    with _$DmChannelDaoMixin {
  DmChannelDao(super.attachedDatabase);

  Stream<List<DmChannel>> watchDmChannels() => (select(
    dmChannels,
  )..orderBy([(d) => OrderingTerm.desc(d.lastMessageTime)])).watch();

  Future<List<DmChannel>> getDmChannels() => (select(
    dmChannels,
  )..orderBy([(d) => OrderingTerm.desc(d.lastMessageTime)])).get();

  Future<void> upsertDmChannels(List<DmChannelsCompanion> channelList) async {
    await batch((b) {
      for (final channel in channelList) {
        b.insert(dmChannels, channel, onConflict: DoUpdate((_) => channel));
      }
    });
  }

  Future<void> clearAll() => delete(dmChannels).go();
}
