import 'package:passkeys/authenticator.dart';
import 'package:passkeys/types.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'webauthn_service.g.dart';

@riverpod
PasskeyAuthenticator passkeyAuthenticator(Ref ref) {
  return PasskeyAuthenticator();
}

/// Wraps the passkeys package for WebAuthn MFA authentication.
class WebAuthnService {
  final PasskeyAuthenticator _authenticator;

  const WebAuthnService(this._authenticator);

  /// Authenticates using WebAuthn with the given server options.
  /// Returns the authentication response as a JSON map.
  Future<Map<String, dynamic>> authenticate(
    Map<String, dynamic> options,
  ) async {
    final request = AuthenticateRequestType.fromJson(options);
    final response = await _authenticator.authenticate(request);
    return response.toJson();
  }
}
