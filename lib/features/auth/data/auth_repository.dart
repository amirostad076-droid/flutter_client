import 'package:dio/dio.dart';
import 'package:fluxer_dart/fluxer_dart.dart';

import 'package:fluxeron/core/database/fluxer_database.dart' hide AuthSession;
import 'package:fluxeron/features/auth/domain/auth_failure.dart';
import 'package:fluxeron/features/auth/domain/auth_session.dart';

class AuthRepository {
  final FluxerDart _client;
  final FluxerDatabase _db;

  const AuthRepository(this._client, this._db);

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final request = LoginRequest(
      (builder) => builder
        ..email = email.trim()
        ..password = password,
    );

    try {
      final response = await _client.getAuthApi().loginUser(
        loginRequest: request,
      );

      final payload = response.data?.oneOf.value;
      if (payload is AuthTokenWithUserIdResponse) {
        final session = AuthSession(
          token: payload.token,
          userId: payload.userId,
        );

        await _db.authSessionDao.saveSession(
          AuthSessionsCompanion.insert(
            token: session.token,
            userId: session.userId,
          ),
        );

        return session;
      }

      if (payload is AuthMfaRequiredResponse) {
        final methods = payload.allowedMethods.join(', ');
        final suffix = methods.isEmpty ? '' : ' ($methods)';
        throw AuthFailure(
          'MFA is required$suffix and is not supported in this client yet.',
        );
      }

      throw const AuthFailure('Unexpected login response from Fluxer API.');
    } on DioException catch (error) {
      throw AuthFailure(_messageFromDio(error));
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

  String _messageFromDio(DioException error) {
    final responseData = error.response?.data;

    if (responseData is Map<String, dynamic>) {
      final message = responseData['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }

      final code = responseData['code'];
      if (code is String && code.isNotEmpty) {
        return code;
      }
    }

    if (responseData is String && responseData.isNotEmpty) {
      return responseData;
    }

    switch (error.response?.statusCode) {
      case 401:
        return 'Invalid email or password.';
      case 429:
        return 'Too many attempts. Please wait and try again.';
    }

    if (error.message != null && error.message!.isNotEmpty) {
      return error.message!;
    }

    return 'Unable to sign in right now. Please try again.';
  }
}
