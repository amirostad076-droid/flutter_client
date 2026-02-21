import 'package:drift/drift.dart';

import 'package:fluxeron/core/database/fluxer_database.dart';
import 'package:fluxeron/core/database/tables/auth_sessions.dart';

part 'auth_session_dao.g.dart';

@DriftAccessor(tables: [AuthSessions])
class AuthSessionDao extends DatabaseAccessor<FluxerDatabase>
    with _$AuthSessionDaoMixin {
  AuthSessionDao(super.attachedDatabase);

  Future<AuthSession?> getSession() =>
      (select(authSessions)..limit(1)).getSingleOrNull();

  Future<void> saveSession(AuthSessionsCompanion session) =>
      into(authSessions).insertOnConflictUpdate(session);

  Future<void> clearSession() => delete(authSessions).go();
}
