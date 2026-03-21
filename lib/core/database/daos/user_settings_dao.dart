import 'package:drift/drift.dart';
import 'package:fluxeron/core/database/fluxer_database.dart';
import 'package:fluxeron/core/database/tables/user_settings.dart';

part 'user_settings_dao.g.dart';

@DriftAccessor(tables: [UserSettingsTable])
class UserSettingsDao extends DatabaseAccessor<FluxerDatabase>
    with _$UserSettingsDaoMixin {
  UserSettingsDao(super.attachedDatabase);

  Future<UserSettingsTableData?> getSettings(String userId) => (select(
    userSettingsTable,
  )..where((t) => t.userId.equals(userId))).getSingleOrNull();

  Stream<UserSettingsTableData?> watchSettings(String userId) => (select(
    userSettingsTable,
  )..where((t) => t.userId.equals(userId))).watchSingleOrNull();

  Future<void> upsertSettings(UserSettingsTableCompanion entry) =>
      into(userSettingsTable).insertOnConflictUpdate(entry);

  Future<void> clearAll() => delete(userSettingsTable).go();
}
