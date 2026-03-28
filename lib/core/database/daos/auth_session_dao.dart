import 'package:drift/drift.dart';

import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/database/tables/auth_sessions.dart';

part 'auth_session_dao.g.dart';

@DriftAccessor(tables: [AuthSessions])
class AuthSessionDao extends DatabaseAccessor<FluxerDatabase>
    with _$AuthSessionDaoMixin {
  AuthSessionDao(super.attachedDatabase);

  /// Returns all stored sessions ordered by most recently active.
  Future<List<AuthSession>> getAllSessions() => (select(
    authSessions,
  )..orderBy([(t) => OrderingTerm.desc(t.lastActive)])).get();

  /// Returns a specific session by user ID.
  Future<AuthSession?> getSession(String userId) => (select(
    authSessions,
  )..where((t) => t.userId.equals(userId))).getSingleOrNull();

  /// Returns the most recently active valid session (for app startup).
  Future<AuthSession?> getActiveSession() =>
      (select(authSessions)
            ..where((t) => t.isValid.equals(true))
            ..orderBy([(t) => OrderingTerm.desc(t.lastActive)])
            ..limit(1))
          .getSingleOrNull();

  /// Upserts a session with updated lastActive timestamp and marks it valid.
  Future<void> saveSession(AuthSessionsCompanion session) =>
      into(authSessions).insertOnConflictUpdate(
        session.copyWith(
          isValid: const Value(true),
          lastActive: Value(DateTime.now()),
        ),
      );

  /// Updates the cached user data for a session.
  Future<void> updateUserData({
    required String userId,
    required String? username,
    required String? discriminator,
    required String? avatar,
  }) => (update(authSessions)..where((t) => t.userId.equals(userId))).write(
    AuthSessionsCompanion(
      username: Value(username),
      discriminator: Value(discriminator),
      avatar: Value(avatar),
      lastActive: Value(DateTime.now()),
    ),
  );

  /// Marks a session as invalid (expired/logged out) without removing it.
  Future<void> markInvalid(String userId) =>
      (update(authSessions)..where((t) => t.userId.equals(userId))).write(
        const AuthSessionsCompanion(isValid: Value(false)),
      );

  /// Removes a single stored session.
  Future<void> removeSession(String userId) =>
      (delete(authSessions)..where((t) => t.userId.equals(userId))).go();

  /// Clears all sessions (full reset).
  Future<void> clearSession() => delete(authSessions).go();
}
