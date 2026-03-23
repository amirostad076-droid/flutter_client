import 'package:flutter/foundation.dart';
import 'package:fluxeron/core/providers/app_startup_provider.dart';
import 'package:fluxeron/features/auth/domain/auth_failure.dart';
import 'package:fluxeron/features/auth/providers/auth_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'login_view_model.g.dart';

class LoginViewState {
  static const _unset = Object();

  final String email;
  final String password;
  final bool isPasswordVisible;
  final String? errorMessage;
  final bool isLoggingIn;

  const LoginViewState({
    required this.email,
    required this.password,
    required this.isPasswordVisible,
    required this.errorMessage,
    required this.isLoggingIn,
  });

  bool get canLogin =>
      !isLoggingIn && email.trim().isNotEmpty && password.isNotEmpty;

  LoginViewState copyWith({
    String? email,
    String? password,
    bool? isPasswordVisible,
    Object? errorMessage = _unset,
    bool? isLoggingIn,
  }) {
    return LoginViewState(
      email: email ?? this.email,
      password: password ?? this.password,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
      isLoggingIn: isLoggingIn ?? this.isLoggingIn,
    );
  }
}

@Riverpod(keepAlive: true)
class LoginViewModel extends _$LoginViewModel {
  @override
  LoginViewState build() {
    return const LoginViewState(
      email: '',
      password: '',
      isPasswordVisible: false,
      errorMessage: null,
      isLoggingIn: false,
    );
  }

  void updateEmail(String value) {
    state = state.copyWith(email: value);
  }

  void updatePassword(String value) {
    state = state.copyWith(password: value);
  }

  void togglePassword() {
    state = state.copyWith(isPasswordVisible: !state.isPasswordVisible);
  }

  Future<bool> login() async {
    if (!state.canLogin) {
      return false;
    }

    state = state.copyWith(errorMessage: null, isLoggingIn: true);

    try {
      await ref
          .read(authRepositoryProvider)
          .login(email: state.email, password: state.password);

      // Session is persisted by AuthRepository. Trigger AppStartup
      // to restore it (sets token, connects gateway, loads theme, etc).
      ref.invalidate(appStartupProvider);

      // Clear credentials from memory after successful login.
      state = state.copyWith(email: '', password: '', isLoggingIn: false);
      return true;
    } on AuthFailure catch (error) {
      state = state.copyWith(errorMessage: error.message, isLoggingIn: false);
      return false;
    } on Exception catch (e) {
      debugPrint('[LoginViewModel] Unexpected error: $e');
      state = state.copyWith(
        errorMessage: 'Unable to sign in right now. Please try again.',
        isLoggingIn: false,
      );
      return false;
    }
  }
}
