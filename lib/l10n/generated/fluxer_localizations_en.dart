// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fluxer_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class FluxerLocalizationsEn extends FluxerLocalizations {
  FluxerLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get reconnectingTitle => 'We fluxed up!';

  @override
  String get reconnectingBody =>
      'Something is wrong with the servers.\nShould be fixed in a second!';

  @override
  String splashStartupFailed(String error) {
    return 'Failed to start: $error';
  }

  @override
  String get retry => 'Retry';

  @override
  String get connectingCaps => 'CONNECTING';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get email => 'Email';

  @override
  String get emailInvalid => 'Please enter a valid email address.';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot your password?';

  @override
  String get logIn => 'Log in';

  @override
  String get logInWithPasskey => 'Log in with a passkey';

  @override
  String get logInViaBrowser => 'Log in via browser';

  @override
  String get needAccountPrompt => 'Need an account? ';

  @override
  String get register => 'Register';

  @override
  String get orDivider => 'OR';

  @override
  String get captchaTitle => 'Verify you\'re human';

  @override
  String get captchaDescription =>
      'We need to make sure you\'re not a bot. Please complete the verification below.';

  @override
  String get captchaSwitchToHcaptcha => 'Having issues? Try hCaptcha instead';

  @override
  String get captchaSwitchToTurnstile => 'Try Turnstile instead';

  @override
  String get cancel => 'Cancel';

  @override
  String get ipAuthCheckEmail => 'Check your email';

  @override
  String ipAuthDescription(String email) {
    return 'We emailed a link to authorize this login. Please open your inbox for $email.';
  }

  @override
  String get ipAuthConnectionLost => 'Connection lost';

  @override
  String get ipAuthConnectionLostDescription =>
      'We lost the connection while waiting for authorization. Please try again.';

  @override
  String get ipAuthResendEmail => 'Resend email';

  @override
  String get ipAuthResent => 'Resent';

  @override
  String ipAuthResendCountdown(int seconds) {
    return '${seconds}s';
  }

  @override
  String get back => 'Back';

  @override
  String get mfaTitle => 'Two-factor authentication';

  @override
  String get mfaChooseMethod => 'Choose a verification method';

  @override
  String get mfaMethodTotp => 'Authenticator App';

  @override
  String get mfaMethodSms => 'SMS Code';

  @override
  String get mfaMethodWebauthn => 'Security Key / Passkey';

  @override
  String get mfaTotpDescription =>
      'Enter the 6-digit code from your authenticator app or one of your backup codes.';

  @override
  String get mfaSmsDescription => 'Enter the 6-digit code sent to your phone.';

  @override
  String get mfaSendSmsCode => 'Send SMS Code';

  @override
  String get mfaCodeLabel => 'Code';

  @override
  String get mfaTryAnotherMethod => 'Try another method';

  @override
  String get mfaUseSecurityKey => 'Try security key / passkey instead';

  @override
  String get accountSelectorTitle => 'Choose an account';

  @override
  String get accountSelectorDescription =>
      'Select an account to continue, or add a different one.';

  @override
  String get accountAdd => 'Add an account';

  @override
  String get accountRemove => 'Remove';

  @override
  String accountRemoveTitle(String username) {
    return 'Remove $username';
  }

  @override
  String get accountRemoveDescription =>
      'This will remove the saved session for this account.';

  @override
  String get accountRemoveOnlyDescription =>
      'This will remove the only saved account on this device.';

  @override
  String get accountExpired => 'Expired';

  @override
  String accountSessionExpired(String identifier) {
    return 'Session expired for $identifier. Please log in again.';
  }

  @override
  String get accountActive => 'Active account';

  @override
  String get signOut => 'Sign out';
}
