import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/features/auth/data/auth_repository.dart';
import 'package:fluxer_app/features/auth/domain/auth_failure.dart';
import 'package:fluxer_app/features/auth/domain/login_result.dart';
import 'package:fluxer_dart/export.dart';

void main() {
  test('login returns an MFA challenge for MFA-required responses', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.fluxer.app/v1'))
      ..httpClientAdapter = const _JsonResponseAdapter(
        expectedPath: '/v1/auth/login',
        responseJson: <String, Object?>{
          'mfa': true,
          'ticket': 'mfa-ticket',
          'allowed_methods': <String>['totp'],
          'totp': true,
          'webauthn': false,
        },
      );

    final db = FluxerDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final repository = AuthRepository(FluxerClient(dio), db);

    await expectLater(
      repository.login(email: ' user@example.com ', password: 'password'),
      completion(
        isA<LoginMfaRequired>()
            .having(
              (LoginMfaRequired result) => result.challenge.ticket,
              'ticket',
              'mfa-ticket',
            )
            .having(
              (LoginMfaRequired result) => result.challenge.totp,
              'totp',
              isTrue,
            )
            .having(
              (LoginMfaRequired result) => result.challenge.sms,
              'sms',
              isFalse,
            )
            .having(
              (LoginMfaRequired result) => result.challenge.webauthn,
              'webauthn',
              isFalse,
            ),
      ),
    );
  });

  test('verifyMfaTotp exposes session timeout as a code field error', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.fluxer.app/v1'))
      ..httpClientAdapter = const _JsonResponseAdapter(
        expectedPath: '/v1/auth/login/mfa/totp',
        statusCode: 400,
        statusMessage: 'Bad Request',
        responseJson: <String, Object?>{
          'code': 'INVALID_FORM_BODY',
          'message': 'Invalid form body.',
          'errors': <Map<String, Object?>>[
            <String, Object?>{
              'field': 'code',
              'message':
                  'Session timed out. Refresh the page and log in again.',
              'code': 'SESSION_TIMEOUT',
            },
          ],
        },
      );

    final db = FluxerDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final repository = AuthRepository(FluxerClient(dio), db);

    await expectLater(
      repository.verifyMfaTotp(ticket: 'mfa-ticket', code: '366117'),
      throwsA(
        isA<AuthFailure>()
            .having(
              (AuthFailure error) => error.message,
              'message',
              'Invalid form body.',
            )
            .having(
              (AuthFailure error) => error.fieldErrors['code'],
              'code field error',
              'Session timed out. Refresh the page and log in again.',
            ),
      ),
    );
  });
}

class _JsonResponseAdapter implements HttpClientAdapter {
  const _JsonResponseAdapter({
    required this.expectedPath,
    required this.responseJson,
    this.statusCode = 200,
    this.statusMessage = 'OK',
  });

  final String expectedPath;
  final Map<String, Object?> responseJson;
  final int statusCode;
  final String statusMessage;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    expect(options.method, 'POST');
    expect(options.uri.path, expectedPath);

    return ResponseBody.fromString(
      jsonEncode(responseJson),
      statusCode,
      statusMessage: statusMessage,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
