import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' hide AuthSession;
import 'package:fluxer_app/features/auth/domain/auth_failure.dart';
import 'package:fluxer_app/features/auth/domain/auth_session.dart';
import 'package:fluxer_app/features/auth/domain/ban_view.dart';
import 'package:fluxer_app/features/auth/domain/ip_authorization_challenge.dart';
import 'package:fluxer_app/features/auth/domain/login_result.dart';
import 'package:fluxer_app/features/auth/domain/mfa_challenge.dart';
import 'package:fluxer_app/features/auth/domain/stored_account.dart';
import 'package:fluxer_dart/export.dart';

class AuthRepository {
  final FluxerClient _client;
  final FluxerDatabase _db;

  const AuthRepository(this._client, this._db);

  Future<LoginResult> login({
    required String email,
    required String password,
    String? inviteCode,
  }) async {
    final request = LoginRequest(
      email: email.trim(),
      password: password,
      inviteCode: inviteCode,
    );

    try {
      final response = await _client.auth.loginUser(body: request);

      try {
        final tokenResponse = response.toAuthTokenWithUserIdResponse();
        final session = AuthSession(
          token: tokenResponse.token,
          userId: tokenResponse.userId,
        );

        await _saveSession(session);

        return LoginSuccess(session);
      } on Object {
        // Not a token response — try MFA
      }

      try {
        final mfaResponse = response.toAuthMfaRequiredResponse();
        return LoginMfaRequired(
          MfaChallenge(
            ticket: mfaResponse.ticket,
            totp: mfaResponse.totp,
            sms: mfaResponse.sms,
            webauthn: mfaResponse.webauthn,
            smsPhoneHint: mfaResponse.smsPhoneHint,
          ),
        );
      } on Object {
        // Not an MFA response either
      }

      // Check for account suspension (ban_view_token in raw JSON).
      final json = response.toJson();
      final banViewToken = json['ban_view_token'] as String?;
      final banType = json['ban_type'] as String?;
      if (banViewToken != null && banType != null) {
        return LoginSuspended(
          BanViewInfo(
            token: banViewToken,
            banType: BanType.fromString(banType),
          ),
        );
      }

      throw const AuthFailure('Unexpected login response from Fluxer API.');
    } on AuthFailure {
      rethrow;
    } on DioException catch (error) {
      final ipChallenge = _extractIpAuthChallenge(error);
      if (ipChallenge != null) {
        return LoginIpAuthRequired(ipChallenge);
      }
      throw _failureFromDio(error);
    }
  }

  Future<void> forgotPassword({required String email}) async {
    try {
      await _client.auth.forgotPassword(
        body: ForgotPasswordRequest(email: email.trim()),
      );
    } on DioException catch (error) {
      throw _failureFromDio(error);
    }
  }

  /// Resets the password using a token from a reset email.
  ///
  /// Returns [LoginSuccess] (auto-login) or [LoginMfaRequired] if the user
  /// has MFA enabled.
  Future<LoginResult> resetPassword({
    required String token,
    required String password,
  }) async {
    try {
      final response = await _client.auth.resetPassword(
        body: ResetPasswordRequest(token: token, password: password),
      );

      try {
        final tokenResponse = response.toAuthTokenWithUserIdResponse();
        final session = AuthSession(
          token: tokenResponse.token,
          userId: tokenResponse.userId,
        );
        await _saveSession(session);
        return LoginSuccess(session);
      } on Object {
        // Not a token response — try MFA
      }

      final mfaResponse = response.toAuthMfaRequiredResponse();
      return LoginMfaRequired(
        MfaChallenge(
          ticket: mfaResponse.ticket,
          totp: mfaResponse.totp,
          sms: mfaResponse.sms,
          webauthn: mfaResponse.webauthn,
          smsPhoneHint: mfaResponse.smsPhoneHint,
        ),
      );
    } on DioException catch (error) {
      throw _failureFromDio(error);
    }
  }

  Future<List<String>> getUsernameSuggestions({
    required String globalName,
  }) async {
    try {
      final response = await _client.auth.getUsernameSuggestions(
        body: UsernameSuggestionsRequest(globalName: globalName),
      );
      return response.suggestions;
    } on DioException catch (error) {
      throw _failureFromDio(error);
    }
  }

  Future<AuthSession> register({
    required String email,
    required String password,
    required String dateOfBirth,
    String? username,
    String? displayName,
    String? inviteCode,
  }) async {
    try {
      final response = await _client.auth.registerAccount(
        body: RegisterRequest(
          email: email.trim(),
          password: password,
          dateOfBirth: dateOfBirth,
          consent: true,
          username: (username?.trim().isNotEmpty ?? false)
              ? username!.trim()
              : null,
          globalName: (displayName?.trim().isNotEmpty ?? false)
              ? displayName!.trim()
              : null,
          inviteCode: inviteCode,
        ),
      );

      final tokenResponse = response.toAuthTokenWithUserIdResponse();
      final session = AuthSession(
        token: tokenResponse.token,
        userId: tokenResponse.userId,
      );
      await _saveSession(session);
      return session;
    } on DioException catch (error) {
      throw _failureFromDio(error);
    }
  }

  Future<AuthSession?> restoreSession() async {
    final row = await _db.authSessionDao.getActiveSession();
    if (row == null) {
      return null;
    }
    return AuthSession(token: row.token, userId: row.userId);
  }

  Future<void> logout(String userId) async {
    try {
      await _client.auth.logoutUser();
    } on Object {
      // Best-effort API call — proceed with local cleanup regardless.
    }
    await _db.authSessionDao.removeSession(userId);
    await _db.clearUserData();
  }

  Future<AuthSession?> pollIpAuthorization(String ticket) async {
    final response = await _client.auth.pollIpAuthorization(ticket: ticket);
    if (response.completed &&
        response.token != null &&
        response.userId != null) {
      final session = AuthSession(
        token: response.token!,
        userId: response.userId!,
      );

      await _saveSession(session);

      return session;
    }
    return null;
  }

  Future<void> resendIpAuthorization(String ticket) async {
    await _client.auth.resendIpAuthorization(
      body: MfaTicketRequest(ticket: ticket),
    );
  }

  Future<void> _saveSession(
    AuthSession session, {
    String? username,
    String? discriminator,
    String? avatar,
  }) async {
    await _db.authSessionDao.saveSession(
      AuthSessionsCompanion.insert(
        token: session.token,
        userId: session.userId,
        username: Value(username),
        discriminator: Value(discriminator),
        avatar: Value(avatar),
      ),
    );
  }

  Future<AuthSession> verifyMfaTotp({
    required String ticket,
    required String code,
  }) async {
    try {
      final response = await _client.auth.loginWithTotp(
        body: MfaTotpRequest(code: code, ticket: ticket),
      );
      final session = AuthSession(
        token: response.token,
        userId: response.userId,
      );
      await _saveSession(session);
      return session;
    } on DioException catch (error) {
      throw _failureFromDio(error);
    }
  }

  Future<AuthSession> verifyMfaSms({
    required String ticket,
    required String code,
  }) async {
    try {
      final response = await _client.auth.loginWithSmsMfa(
        body: MfaSmsRequest(code: code, ticket: ticket),
      );
      final session = AuthSession(
        token: response.token,
        userId: response.userId,
      );
      await _saveSession(session);
      return session;
    } on DioException catch (error) {
      throw _failureFromDio(error);
    }
  }

  Future<void> sendMfaSms({required String ticket}) async {
    try {
      await _client.auth.sendSmsMfaCode(body: MfaTicketRequest(ticket: ticket));
    } on DioException catch (error) {
      throw _failureFromDio(error);
    }
  }

  Future<dynamic> getMfaWebauthnOptions({required String ticket}) async {
    try {
      return await _client.auth.getWebauthnMfaOptions(
        body: MfaTicketRequest(ticket: ticket),
      );
    } on DioException catch (error) {
      throw _failureFromDio(error);
    }
  }

  Future<AuthSession> verifyMfaWebauthn({
    required String ticket,
    required dynamic response,
    required String challenge,
  }) async {
    try {
      final result = await _client.auth.loginWithWebauthnMfa(
        body: WebAuthnMfaRequest(
          response: response,
          challenge: challenge,
          ticket: ticket,
        ),
      );
      final session = AuthSession(token: result.token, userId: result.userId);
      await _saveSession(session);
      return session;
    } on DioException catch (error) {
      throw _failureFromDio(error);
    }
  }

  Future<dynamic> getPasskeyLoginOptions() async {
    try {
      return await _client.auth.getWebauthnAuthenticationOptions();
    } on DioException catch (error) {
      throw _failureFromDio(error);
    }
  }

  Future<LoginResult> loginWithPasskey({
    required dynamic response,
    required String challenge,
  }) async {
    try {
      final result = await _client.auth.authenticateWithWebauthn(
        body: WebAuthnAuthenticateRequest(
          response: response,
          challenge: challenge,
        ),
      );
      final session = AuthSession(token: result.token, userId: result.userId);
      await _saveSession(session);
      return LoginSuccess(session);
    } on DioException catch (error) {
      final ipChallenge = _extractIpAuthChallenge(error);
      if (ipChallenge != null) {
        return LoginIpAuthRequired(ipChallenge);
      }
      throw _failureFromDio(error);
    }
  }

  Future<void> updateStoredUserData({
    required String userId,
    required String? username,
    required String? discriminator,
    required String? avatar,
  }) async {
    await _db.authSessionDao.updateUserData(
      userId: userId,
      username: username,
      discriminator: discriminator,
      avatar: avatar,
    );
  }

  Future<List<StoredAccount>> getStoredAccounts() async {
    final sessions = await _db.authSessionDao.getAllSessions();
    return sessions
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
        .toList();
  }

  Future<void> removeStoredAccount(String userId) async {
    await _db.authSessionDao.removeSession(userId);
  }

  IpAuthorizationChallenge? _extractIpAuthChallenge(DioException error) {
    if (error.response?.statusCode != 403) {
      return null;
    }

    final data = error.response?.data;
    if (data is! Map<String, dynamic>) {
      return null;
    }

    final code = data['code'] as String?;
    if (code != 'IP_AUTHORIZATION_REQUIRED') {
      return null;
    }

    final ticket = data['ticket'] as String?;
    final email = data['email'] as String?;
    final resendIn = data['resend_available_in'] as int?;

    if (ticket == null || email == null) {
      return null;
    }

    return IpAuthorizationChallenge(
      ticket: ticket,
      email: email,
      resendAvailableIn: resendIn ?? 0,
    );
  }

  AuthFailure _failureFromDio(DioException error) {
    final responseData = error.response?.data;

    if (responseData is Map<String, dynamic>) {
      try {
        final apiError = Error.fromJson(responseData);
        final validationErrors = apiError.errors;

        // Map field-specific validation errors by path.
        if (validationErrors != null && validationErrors.isNotEmpty) {
          final fieldErrors = <String, String>{};
          for (final e in validationErrors) {
            fieldErrors.putIfAbsent(e.path, () => e.message);
          }
          return AuthFailure(apiError.message, fieldErrors: fieldErrors);
        }

        if (apiError.message.isNotEmpty) {
          return AuthFailure(apiError.message);
        }
      } on Object {
        // Fallback to raw extraction if the SDK model can't parse it.
        final message = responseData['message'];
        if (message is String && message.isNotEmpty) {
          return AuthFailure(message);
        }
      }
    }

    if (responseData is String && responseData.isNotEmpty) {
      return AuthFailure(responseData);
    }

    switch (error.response?.statusCode) {
      case 401:
        return const AuthFailure('Invalid email or password.');
      case 429:
        return const AuthFailure(
          'Too many attempts. Please wait and try again.',
        );
    }

    if (error.message != null && error.message!.isNotEmpty) {
      return AuthFailure(error.message!);
    }

    return const AuthFailure('Unable to sign in right now. Please try again.');
  }
}
