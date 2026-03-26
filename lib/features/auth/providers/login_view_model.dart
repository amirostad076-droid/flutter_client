import 'dart:async';

import 'package:fluxeron/core/providers/app_startup_provider.dart';
import 'package:fluxeron/core/talker.dart';
import 'package:fluxeron/features/auth/domain/auth_failure.dart';
import 'package:fluxeron/features/auth/domain/ban_view.dart';
import 'package:fluxeron/features/auth/domain/ip_authorization_challenge.dart';
import 'package:fluxeron/features/auth/domain/login_result.dart';
import 'package:fluxeron/features/auth/domain/mfa_challenge.dart';
import 'package:fluxeron/features/auth/providers/auth_providers.dart';
import 'package:fluxeron/features/auth/providers/ban_view_provider.dart';
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
  final BanViewInfo? banViewInfo;
  final bool showAccountSelector;
  final bool showForgotPassword;
  final bool forgotPasswordEmailSent;
  final String? resetToken;

  const LoginViewState({
    required this.email,
    required this.password,
    required this.isPasswordVisible,
    required this.errorMessage,
    required this.fieldErrors,
    required this.isLoggingIn,
    required this.ipAuthChallenge,
    required this.mfaChallenge,
    required this.banViewInfo,
    required this.showAccountSelector,
    required this.showForgotPassword,
    required this.forgotPasswordEmailSent,
    required this.resetToken,
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
    Object? banViewInfo = _unset,
    bool? showAccountSelector,
    bool? showForgotPassword,
    bool? forgotPasswordEmailSent,
    Object? resetToken = _unset,
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
      banViewInfo: banViewInfo == _unset
          ? this.banViewInfo
          : banViewInfo as BanViewInfo?,
      showAccountSelector: showAccountSelector ?? this.showAccountSelector,
      showForgotPassword: showForgotPassword ?? this.showForgotPassword,
      forgotPasswordEmailSent:
          forgotPasswordEmailSent ?? this.forgotPasswordEmailSent,
      resetToken: resetToken == _unset
          ? this.resetToken
          : resetToken as String?,
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
      banViewInfo: null,
      showAccountSelector: true,
      showForgotPassword: false,
      forgotPasswordEmailSent: false,
      resetToken: null,
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

  void clearBanView() {
    ref.read(banViewProvider.notifier).clear();
    state = state.copyWith(banViewInfo: null);
  }

  void setError(String message) {
    state = state.copyWith(errorMessage: message);
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

  void showForgotPasswordScreen() {
    state = state.copyWith(
      showForgotPassword: true,
      forgotPasswordEmailSent: false,
      errorMessage: null,
      fieldErrors: const {},
    );
  }

  void backFromForgotPassword() {
    state = state.copyWith(
      showForgotPassword: false,
      forgotPasswordEmailSent: false,
      errorMessage: null,
      fieldErrors: const {},
    );
  }

  void setResetToken(String token) {
    state = state.copyWith(
      resetToken: token,
      showForgotPassword: false,
      forgotPasswordEmailSent: false,
      errorMessage: null,
      fieldErrors: const {},
    );
  }

  void clearResetToken() {
    state = state.copyWith(
      resetToken: null,
      errorMessage: null,
      fieldErrors: const {},
    );
  }

  Future<void> submitForgotPassword(String email) async {
    if (email.trim().isEmpty) {
      return;
    }

    state = state.copyWith(
      isLoggingIn: true,
      errorMessage: null,
      fieldErrors: const {},
    );

    try {
      await ref.read(authRepositoryProvider).forgotPassword(email: email);
      state = state.copyWith(forgotPasswordEmailSent: true, isLoggingIn: false);
    } on AuthFailure catch (error) {
      state = state.copyWith(
        errorMessage: error.fieldErrors.isEmpty ? error.message : null,
        fieldErrors: error.fieldErrors,
        isLoggingIn: false,
      );
    } on Exception catch (e) {
      talker.error('[LoginViewModel] Forgot password error: $e');
      state = state.copyWith(
        errorMessage: 'Unable to send reset link. Please try again.',
        isLoggingIn: false,
      );
    }
  }

  Future<void> submitResetPassword({
    required String token,
    required String password,
  }) async {
    state = state.copyWith(
      isLoggingIn: true,
      errorMessage: null,
      fieldErrors: const {},
    );

    try {
      final result = await ref
          .read(authRepositoryProvider)
          .resetPassword(token: token, password: password);

      switch (result) {
        case LoginSuccess():
          ref.invalidate(appStartupProvider);
          state = state.copyWith(
            email: '',
            password: '',
            resetToken: null,
            isLoggingIn: false,
          );
        case LoginMfaRequired(:final challenge):
          state = state.copyWith(
            mfaChallenge: challenge,
            resetToken: null,
            isLoggingIn: false,
          );
        case LoginIpAuthRequired(:final challenge):
          state = state.copyWith(
            ipAuthChallenge: challenge,
            resetToken: null,
            isLoggingIn: false,
          );
        case LoginSuspended(:final banViewInfo):
          unawaited(ref.read(banViewProvider.notifier).initialize(banViewInfo));
          state = state.copyWith(
            banViewInfo: banViewInfo,
            resetToken: null,
            isLoggingIn: false,
          );
      }
    } on AuthFailure catch (error) {
      state = state.copyWith(
        errorMessage: error.fieldErrors.isEmpty ? error.message : null,
        fieldErrors: error.fieldErrors,
        isLoggingIn: false,
      );
    } on Exception catch (e) {
      talker.error('[LoginViewModel] Reset password error: $e');
      state = state.copyWith(
        errorMessage: 'Unable to reset password. Please try again.',
        isLoggingIn: false,
      );
    }
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
          state = state.copyWith(mfaChallenge: challenge, isLoggingIn: false);
          return false;
        case LoginSuspended(:final banViewInfo):
          unawaited(ref.read(banViewProvider.notifier).initialize(banViewInfo));
          state = state.copyWith(banViewInfo: banViewInfo, isLoggingIn: false);
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
