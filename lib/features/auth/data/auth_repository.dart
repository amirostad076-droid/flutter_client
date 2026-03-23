import 'package:dio/dio.dart';
import 'package:fluxer_dart/export.dart';

import 'package:fluxeron/core/database/fluxer_database.dart' hide AuthSession;
import 'package:fluxeron/features/auth/domain/auth_failure.dart';
import 'package:fluxeron/features/auth/domain/auth_session.dart';

class AuthRepository {
  final FluxerClient _client;
  final FluxerDatabase _db;

  const AuthRepository(this._client, this._db);

  Future<AuthSession> login({
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

        return session;
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
