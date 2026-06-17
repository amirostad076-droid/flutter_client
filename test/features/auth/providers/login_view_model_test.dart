import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/auth/data/auth_repository.dart';
import 'package:fluxer_app/features/auth/domain/auth_failure.dart';
import 'package:fluxer_app/features/auth/domain/login_result.dart';
import 'package:fluxer_app/features/auth/providers/auth_providers.dart';
import 'package:fluxer_app/features/auth/providers/login_view_model.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.failure);

  final AuthFailure failure;

  @override
  Future<LoginResult> login({
    required String email,
    required String password,
    String? inviteCode,
  }) {
    return Future<LoginResult>.error(failure);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ProviderContainer _containerFor(AuthFailure failure) {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository(failure)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('an invalid-credentials failure shows a single general error', () async {
    final container = _containerFor(
      const AuthFailure(
        'Invalid email or password.',
        kind: AuthFailureKind.invalidCredentials,
      ),
    );
    container.read(loginViewModelProvider.notifier)
      ..updateEmail('user@example.com')
      ..updatePassword('wrong-password');

    await container.read(loginViewModelProvider.notifier).login();

    final state = container.read(loginViewModelProvider);
    expect(state.errorType, LoginError.invalidCredentials);
    expect(state.fieldErrors, isEmpty);
    expect(state.errorMessage, isNull);
  });

  test('a field validation failure keeps per-field errors', () async {
    final container = _containerFor(
      const AuthFailure(
        'Invalid form body.',
        fieldErrors: {'email': 'Enter a valid email.'},
      ),
    );
    container.read(loginViewModelProvider.notifier)
      ..updateEmail('user@example.com')
      ..updatePassword('whatever');

    await container.read(loginViewModelProvider.notifier).login();

    final state = container.read(loginViewModelProvider);
    expect(state.fieldErrors['email'], 'Enter a valid email.');
    expect(state.errorType, isNull);
    expect(state.errorMessage, isNull);
  });
}
