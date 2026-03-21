import 'package:drift/drift.dart';

import 'package:fluxeron/core/database/fluxer_database.dart';
import 'package:fluxeron/core/database/tables/read_states.dart';

part 'read_state_dao.g.dart';

@DriftAccessor(tables: [ReadStates])
class ReadStateDao extends DatabaseAccessor<FluxerDatabase>
    with _$ReadStateDaoMixin {
  ReadStateDao(super.attachedDatabase);

  Future<ReadState?> getReadState(String channelId) => (select(
    readStates,
  )..where((r) => r.channelId.equals(channelId))).getSingleOrNull();

  Stream<List<ReadState>> watchReadStates() => select(readStates).watch();

  Stream<ReadState?> watchReadState(String channelId) => (select(
    readStates,
  )..where((r) => r.channelId.equals(channelId))).watchSingleOrNull();

  Future<void> upsertReadState(ReadStatesCompanion state) =>
      into(readStates).insertOnConflictUpdate(state);

  Future<void> updatePinTimestamp(String channelId, String? timestamp) =>
      (update(readStates)..where((r) => r.channelId.equals(channelId))).write(
        ReadStatesCompanion(lastPinTimestamp: Value(timestamp)),
      );

  Stream<List<ReadState>> watchReadStatesForChannels(List<String> channelIds) =>
      (select(readStates)..where((r) => r.channelId.isIn(channelIds))).watch();

  Future<void> clearAll() => delete(readStates).go();
}
