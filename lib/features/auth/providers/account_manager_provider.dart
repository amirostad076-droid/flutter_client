import 'package:drift/drift.dart';
import 'package:fluxeron/core/api/fluxer_client_provider.dart';
import 'package:fluxeron/core/database/fluxer_database.dart' hide AuthSession;
import 'package:fluxeron/core/providers/app_startup_provider.dart';
import 'package:fluxeron/core/providers/database_provider.dart';
import 'package:fluxeron/core/router/fluxer_router.dart';
import 'package:fluxeron/core/talker.dart';
import 'package:fluxeron/features/auth/domain/auth_failure.dart';
import 'package:fluxeron/features/auth/domain/stored_account.dart';
import 'package:fluxeron/features/auth/providers/auth_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'account_manager_provider.g.dart';

class AccountManagerState {
  final List<StoredAccount> accounts;
  final bool isSwitching;

  const AccountManagerState({
    required this.accounts,
    required this.isSwitching,
  });

  AccountManagerState copyWith({
    List<StoredAccount>? accounts,
    bool? isSwitching,
  }) {
    return AccountManagerState(
      accounts: accounts ?? this.accounts,
      isSwitching: isSwitching ?? this.isSwitching,
    );
  }
}

@Riverpod(keepAlive: true)
class AccountManager extends _$AccountManager {
  @override
  AccountManagerState build() {
    return const AccountManagerState(accounts: [], isSwitching: false);
  }

  /// Loads stored accounts from the database.
  Future<void> loadAccounts() async {
    final db = ref.read(fluxerDatabaseProvider);
    final sessions = await db.authSessionDao.getAllSessions();
    state = state.copyWith(
      accounts: sessions
          .map(
            (s) => StoredAccount(
              userId: s.userId,
              isValid: s.isValid,
              lastActive: s.lastActive,
              username: s.username,
              discriminator: s.discriminator,
              avatar: s.avatar,
            ),
          )
          .toList(),
    );
  }

  /// Switches to a different stored account by invalidating app startup.
  Future<void> switchToAccount(String userId) async {
    state = state.copyWith(isSwitching: true);

    try {
      final db = ref.read(fluxerDatabaseProvider);
      final session = await db.authSessionDao.getSession(userId);

      if (session == null || !session.isValid) {
        throw const AuthFailure('Session is no longer valid.');
      }

      // Update lastActive to make this the active session.
      await db.authSessionDao.saveSession(
        AuthSessionsCompanion.insert(
          token: session.token,
          userId: session.userId,
          username: Value(session.username),
          discriminator: Value(session.discriminator),
          avatar: Value(session.avatar),
        ),
      );

      // Trigger full app restart with new session.
      ref.invalidate(appStartupProvider);

      state = state.copyWith(isSwitching: false);
    } on Exception catch (e) {
      talker.error('[AccountManager] Switch failed: $e');
      state = state.copyWith(isSwitching: false);
      rethrow;
    }
  }

  /// Signs out the current account (marks invalid, switches to next or login).
  Future<void> signOut(String userId) async {
    final repo = ref.read(authRepositoryProvider);

    await repo.logout(userId);
    await loadAccounts();

    // Try switching to next valid account.
    final nextValid = state.accounts.where((a) => a.isValid).firstOrNull;
    if (nextValid != null) {
      await switchToAccount(nextValid.userId);
    } else {
      // No valid sessions — go to login.
      ref.read(fluxerAuthTokenProvider.notifier).setToken(null);
      ref.read(authStateProvider.notifier).setAuthenticated(value: false);
      ref.read(currentUserIdProvider.notifier).set('');
    }
  }

  /// Removes a stored account entirely.
  Future<void> removeAccount(String userId) async {
    final db = ref.read(fluxerDatabaseProvider);
    await db.authSessionDao.removeSession(userId);
    await loadAccounts();
  }
}
