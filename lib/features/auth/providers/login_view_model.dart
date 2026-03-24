import 'package:fluxeron/core/providers/app_startup_provider.dart';
import 'package:fluxeron/core/talker.dart';
import 'package:fluxeron/features/auth/domain/auth_failure.dart';
import 'package:fluxeron/features/auth/domain/ip_authorization_challenge.dart';
import 'package:fluxeron/features/auth/domain/login_result.dart';
import 'package:fluxeron/features/auth/domain/mfa_challenge.dart';
import 'package:fluxeron/features/auth/providers/auth_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'login_view_model.g.dart';

class LoginViewState {
  static const _unset = Object();

  final String email;
  final String password;
  final bool isPasswordVisible;
  final String? errorMessage;
  final Map<String, String> fieldErrors;
  final bool isLoggingIn;
  final IpAuthorizationChallenge? ipAuthChallenge;
  final MfaChallenge? mfaChallenge;
  final bool showAccountSelector;

  const LoginViewState({
    required this.email,
    required this.password,
    required this.isPasswordVisible,
    required this.errorMessage,
    required this.fieldErrors,
    required this.isLoggingIn,
    required this.ipAuthChallenge,
    required this.mfaChallenge,
    required this.showAccountSelector,
  });

  bool get canLogin =>
      !isLoggingIn && email.trim().isNotEmpty && password.isNotEmpty;

  LoginViewState copyWith({
    String? email,
    String? password,
    bool? isPasswordVisible,
    Object? errorMessage = _unset,
    Map<String, String>? fieldErrors,
    bool? isLoggingIn,
    Object? ipAuthChallenge = _unset,
    Object? mfaChallenge = _unset,
    bool? showAccountSelector,
  }) {
    return LoginViewState(
      email: email ?? this.email,
      password: password ?? this.password,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      isLoggingIn: isLoggingIn ?? this.isLoggingIn,
      ipAuthChallenge: ipAuthChallenge == _unset
          ? this.ipAuthChallenge
          : ipAuthChallenge as IpAuthorizationChallenge?,
      mfaChallenge: mfaChallenge == _unset
          ? this.mfaChallenge
          : mfaChallenge as MfaChallenge?,
      showAccountSelector:
          showAccountSelector ?? this.showAccountSelector,
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
      fieldErrors: {},
      isLoggingIn: false,
      ipAuthChallenge: null,
      mfaChallenge: null,
      showAccountSelector: true,
    );
  }

  void updateEmail(String value) {
    state = state.copyWith(
      email: value,
      fieldErrors: state.fieldErrors.containsKey('email')
          ? const {}
          : state.fieldErrors,
    );
  }

  void updatePassword(String value) {
    state = state.copyWith(password: value);
  }

  void togglePassword() {
    state = state.copyWith(isPasswordVisible: !state.isPasswordVisible);
  }

  void clearIpAuthChallenge() {
    state = state.copyWith(ipAuthChallenge: null);
  }

  void clearMfaChallenge() {
    state = state.copyWith(mfaChallenge: null);
  }

  void hideAccountSelector() {
    state = state.copyWith(showAccountSelector: false);
  }

  void showAccountSelectorAgain() {
    state = state.copyWith(showAccountSelector: true);
  }

  void completeMfa() {
    ref.invalidate(appStartupProvider);
    state = state.copyWith(
      email: '',
      password: '',
      mfaChallenge: null,
      isLoggingIn: false,
    );
  }

  void completeIpAuth() {
    ref.invalidate(appStartupProvider);
    state = state.copyWith(
      email: '',
      password: '',
      ipAuthChallenge: null,
      isLoggingIn: false,
    );
  }

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  Future<bool> login() async {
    if (!state.canLogin) {
      return false;
    }

    if (!_emailRegex.hasMatch(state.email.trim())) {
      state = state.copyWith(
        fieldErrors: const {'email': 'Please enter a valid email address.'},
      );
      return false;
    }

    state = state.copyWith(
      errorMessage: null,
      fieldErrors: const {},
      isLoggingIn: true,
    );

    try {
      final result = await ref
          .read(authRepositoryProvider)
          .login(email: state.email, password: state.password);

      switch (result) {
        case LoginSuccess():
          ref.invalidate(appStartupProvider);
          state = state.copyWith(email: '', password: '', isLoggingIn: false);
          return true;
        case LoginIpAuthRequired(:final challenge):
          state = state.copyWith(
            ipAuthChallenge: challenge,
            isLoggingIn: false,
          );
          return false;
        case LoginMfaRequired(:final challenge):
          state = state.copyWith(
            mfaChallenge: challenge,
            isLoggingIn: false,
          );
          return false;
      }
    } on AuthFailure catch (error) {
      state = state.copyWith(
        errorMessage: error.fieldErrors.isEmpty ? error.message : null,
        fieldErrors: error.fieldErrors,
        isLoggingIn: false,
      );
      return false;
    } on Exception catch (e) {
      talker.error('[LoginViewModel] Unexpected error: $e');
      state = state.copyWith(
        errorMessage: 'Unable to sign in right now. Please try again.',
        isLoggingIn: false,
      );
      return false;
    }
  }
}
