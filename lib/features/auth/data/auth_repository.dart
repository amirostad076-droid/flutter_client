import 'package:dio/dio.dart';
import 'package:fluxer_dart/export.dart';

import 'package:fluxeron/core/database/fluxer_database.dart' hide AuthSession;
import 'package:fluxeron/features/auth/domain/auth_failure.dart';
import 'package:fluxeron/features/auth/domain/auth_session.dart';
import 'package:fluxeron/features/auth/domain/ip_authorization_challenge.dart';
import 'package:fluxeron/features/auth/domain/login_result.dart';

class AuthRepository {
  final FluxerClient _client;
  final FluxerDatabase _db;

  const AuthRepository(this._client, this._db);

  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final request = LoginRequest(email: email.trim(), password: password);

    try {
      final response = await _client.auth.loginUser(body: request);

      try {
        final tokenResponse = response.toAuthTokenWithUserIdResponse();
        final session = AuthSession(
          token: tokenResponse.token,
          userId: tokenResponse.userId,
        );

        await _db.authSessionDao.saveSession(
          AuthSessionsCompanion.insert(
            token: session.token,
            userId: session.userId,
          ),
        );

        return LoginSuccess(session);
      } on Object {
        // Not a token response — try MFA
      }

      try {
        final mfaResponse = response.toAuthMfaRequiredResponse();
        final methods = mfaResponse.allowedMethods.join(', ');
        final suffix = methods.isEmpty ? '' : ' ($methods)';
        throw AuthFailure(
          'MFA is required$suffix and is not supported in this client yet.',
        );
      } on AuthFailure {
        rethrow;
      } on Object {
        // Not an MFA response either
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

  Future<AuthSession?> restoreSession() async {
    final row = await _db.authSessionDao.getSession();
    if (row == null) {
      return null;
    }
    return AuthSession(token: row.token, userId: row.userId);
  }

  Future<void> logout() async {
    await _db.clearAll();
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

      await _db.authSessionDao.saveSession(
        AuthSessionsCompanion.insert(
          token: session.token,
          userId: session.userId,
        ),
      );

      return session;
    }
    return null;
  }

  Future<void> resendIpAuthorization(String ticket) async {
    await _client.auth.resendIpAuthorization(
      body: MfaTicketRequest(ticket: ticket),
    );
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
