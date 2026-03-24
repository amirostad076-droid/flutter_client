import 'package:fluxeron/features/auth/domain/auth_session.dart';
import 'package:fluxeron/features/auth/domain/ip_authorization_challenge.dart';
import 'package:fluxeron/features/auth/domain/mfa_challenge.dart';

sealed class LoginResult {
  const LoginResult();
}

class LoginSuccess extends LoginResult {
  final AuthSession session;
  const LoginSuccess(this.session);
}

class LoginIpAuthRequired extends LoginResult {
  final IpAuthorizationChallenge challenge;
  const LoginIpAuthRequired(this.challenge);
}

class LoginMfaRequired extends LoginResult {
  final MfaChallenge challenge;
  const LoginMfaRequired(this.challenge);
}
