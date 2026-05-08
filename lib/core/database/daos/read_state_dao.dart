import 'package:drift/drift.dart';

import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/database/tables/read_states.dart';

part 'read_state_dao.g.dart';

@DriftAccessor(tables: [ReadStates])
class ReadStateDao extends DatabaseAccessor<FluxerDatabase>
    with _$ReadStateDaoMixin {
  ReadStateDao(super.attachedDatabase);

  Future<ReadState?> getReadState(String channelId) => (select(
    readStates,
  )..where((r) => r.channelId.equals(channelId))).getSingleOrNull();

  Future<List<ReadState>> getReadStates() => select(readStates).get();

  Stream<List<ReadState>> watchReadStates() => select(readStates).watch();

  Stream<ReadState?> watchReadState(String channelId) => (select(
    readStates,
  )..where((r) => r.channelId.equals(channelId))).watchSingleOrNull();

  Future<void> upsertReadState(ReadStatesCompanion state) =>
      into(readStates).insertOnConflictUpdate(state);

  Future<void> incrementMentionCount(String channelId) =>
      transaction(() async {
        final existing = await getReadState(channelId);
        await upsertReadState(
          ReadStatesCompanion(
            channelId: Value(channelId),
            lastMessageId: Value(existing?.lastMessageId),
            mentionCount: Value((existing?.mentionCount ?? 0) + 1),
            lastPinTimestamp: Value(existing?.lastPinTimestamp),
            manual: Value(existing?.manual ?? false),
          ),
        );
      });

  Future<void> updatePinTimestamp(String channelId, String? timestamp) =>
      transaction(() async {
        final existing = await getReadState(channelId);
        await upsertReadState(
          ReadStatesCompanion(
            channelId: Value(channelId),
            lastMessageId: Value(existing?.lastMessageId),
            mentionCount: Value(existing?.mentionCount ?? 0),
            lastPinTimestamp: Value(timestamp),
            manual: Value(existing?.manual ?? false),
          ),
        );
      });

  Future<void> setManual(String channelId, {required bool manual}) =>
      (update(readStates)..where((r) => r.channelId.equals(channelId))).write(
        ReadStatesCompanion(manual: Value(manual)),
      );

  Future<void> deleteReadState(String channelId) =>
      (delete(readStates)..where((r) => r.channelId.equals(channelId))).go();

  Stream<List<ReadState>> watchReadStatesForChannels(List<String> channelIds) =>
      (select(readStates)..where((r) => r.channelId.isIn(channelIds))).watch();

  Future<void> clearAll() => delete(readStates).go();
}
