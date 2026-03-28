import 'package:drift/drift.dart';

import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/database/tables/user_preferences.dart';

part 'user_preferences_dao.g.dart';

@DriftAccessor(tables: [UserPreferencesTable])
class UserPreferencesDao extends DatabaseAccessor<FluxerDatabase>
    with _$UserPreferencesDaoMixin {
  UserPreferencesDao(super.attachedDatabase);

  Future<UserPreferencesTableData?> getPreferences(String userId) => (select(
    userPreferencesTable,
  )..where((t) => t.userId.equals(userId))).getSingleOrNull();

  Future<void> savePreferences(UserPreferencesTableCompanion prefs) =>
      into(userPreferencesTable).insertOnConflictUpdate(prefs);

  Future<void> clearAll() => delete(userPreferencesTable).go();
}
