import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/build/push_provider_guard.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' hide AuthSession;
import 'package:fluxer_app/core/providers/app_startup_provider.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/push/apns/apns_mobile_device_registration.dart';
import 'package:fluxer_app/core/push/fcm/fcm_mobile_device_registration.dart';
import 'package:fluxer_app/core/push/services/unified_push_service.dart';
import 'package:fluxer_app/core/push/unified_push/unified_push_mobile_device_registration.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/talker.dart';
import 'package:fluxer_app/features/auth/domain/auth_failure.dart';
import 'package:fluxer_app/features/auth/domain/stored_account.dart';
import 'package:fluxer_app/features/auth/providers/auth_providers.dart';
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

  /// Switches to a different stored account.
  ///
  /// Validates the token with the server first (`GET /users/@me`). If the
  /// token is expired or invalid, the account is marked invalid and a
  /// [SessionExpiredFailure] is thrown so the UI can prompt re-login.
  Future<void> switchToAccount(String userId) async {
    state = state.copyWith(isSwitching: true);

    try {
      final db = ref.read(fluxerDatabaseProvider);
      final session = await db.authSessionDao.getSession(userId);

      if (session == null || !session.isValid) {
        throw const AuthFailure('Session is no longer valid.');
      }

      // Validate the stored token against the server before switching.
      final isValid = await _validateToken(session.token);
      if (!isValid) {
        await db.authSessionDao.markInvalid(userId);
        await loadAccounts();
        state = state.copyWith(isSwitching: false);
        throw SessionExpiredFailure(userId);
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

      if (PushProviderGuard.isApple) {
        await ref
            .read(apnsMobileDeviceRegistrationProvider.notifier)
            .unregisterCurrentToken();
      }
      if (PushProviderGuard.isFirebaseMessaging) {
        await ref
            .read(fcmMobileDeviceRegistrationProvider.notifier)
            .unregisterCurrentToken();
      }

      // Trigger full app restart with new session.
      ref.invalidate(appStartupProvider);

      state = state.copyWith(isSwitching: false);
    } on SessionExpiredFailure {
      rethrow;
    } on Exception catch (e) {
      talker.error('[AccountManager] Switch failed: $e');
      state = state.copyWith(isSwitching: false);
      rethrow;
    }
  }

  /// Validates a token by calling `GET /users/@me` with the account's own
  /// token. Returns `false` on 401 or network failure.
  Future<bool> _validateToken(String token) async {
    try {
      final baseUrl = ref.read(fluxerBaseUrlProvider);
      await Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: {'Authorization': token},
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      ).get<void>('/users/@me');
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return false;
      }
      // Network errors — don't mark invalid, just fail the switch.
      rethrow;
    }
  }

  /// Signs out an account and navigates to login (which shows account selector).
  Future<void> signOut(String userId) async {
    final repo = ref.read(authRepositoryProvider);

    if (PushProviderGuard.isApple) {
      await ref
          .read(apnsMobileDeviceRegistrationProvider.notifier)
          .unregisterCurrentToken();
    }
    if (PushProviderGuard.isFirebaseMessaging) {
      await ref
          .read(fcmMobileDeviceRegistrationProvider.notifier)
          .unregisterCurrentToken();
    }
    if (PushProviderGuard.isUnifiedPush) {
      await ref
          .read(unifiedPushMobileDeviceRegistrationProvider.notifier)
          .unregisterCurrentEndpoint();
      await UnifiedPushService.instance.unregisterFromDistributor();
    }
    await repo.logout(userId);
    await loadAccounts();

    // Always go to login — account selector shows remaining accounts.
    ref.read(fluxerAuthTokenProvider.notifier).setToken(null);
    ref.read(authStateProvider.notifier).setAuthenticated(value: false);
  }

  /// Removes a non-current stored account (invalidates its server session
  /// using the account's own token, then deletes locally).
  Future<void> removeAccount(String userId) async {
    final db = ref.read(fluxerDatabaseProvider);
    final session = await db.authSessionDao.getSession(userId);

    if (session != null) {
      // Best-effort server logout using the stored account's own token,
      // matching the web app behavior (skipAuth + account-specific token).
      try {
        final baseUrl = ref.read(fluxerBaseUrlProvider);
        await Dio(
          BaseOptions(
            baseUrl: baseUrl,
            headers: {'Authorization': session.token},
            connectTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
          ),
        ).post<void>('/auth/logout');
      } on Object catch (e) {
        talker.warning('[AccountManager] Failed to logout stored account: $e');
      }

      await db.authSessionDao.removeSession(userId);
    }

    await loadAccounts();
  }
}
