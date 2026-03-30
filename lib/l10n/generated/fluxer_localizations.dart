import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'fluxer_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of FluxerLocalizations
/// returned by `FluxerLocalizations.of(context)`.
///
/// Applications need to include `FluxerLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/fluxer_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: FluxerLocalizations.localizationsDelegates,
///   supportedLocales: FluxerLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the FluxerLocalizations.supportedLocales
/// property.
abstract class FluxerLocalizations {
  FluxerLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static FluxerLocalizations of(BuildContext context) {
    return Localizations.of<FluxerLocalizations>(context, FluxerLocalizations)!;
  }

  static const LocalizationsDelegate<FluxerLocalizations> delegate =
      _FluxerLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// Title on the reconnecting / server error screen.
  ///
  /// In en, this message translates to:
  /// **'We fluxed up!'**
  String get reconnectingTitle;

  /// Subtitle on the reconnecting screen explaining temporary server issues.
  ///
  /// In en, this message translates to:
  /// **'Something is wrong with the servers.\nShould be fixed in a second!'**
  String get reconnectingBody;

  /// Error message on the splash screen when app startup fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to start: {error}'**
  String splashStartupFailed(String error);

  /// Generic label for retry actions (splash, errors, network, etc.).
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Connecting text on the splash screen
  ///
  /// In en, this message translates to:
  /// **'CONNECTING'**
  String get connectingCaps;

  /// Greeting on the login screen; usable wherever returning users are welcomed.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// Generic label for an email field.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Error shown when the email field contains an invalid email format.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get emailInvalid;

  /// Generic label for a password field.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Link or button to start password recovery.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get forgotPassword;

  /// Primary login submit action.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get logIn;

  /// Secondary login using a passkey.
  ///
  /// In en, this message translates to:
  /// **'Log in with a passkey'**
  String get logInWithPasskey;

  /// Secondary login that opens or uses the system browser.
  ///
  /// In en, this message translates to:
  /// **'Log in via browser'**
  String get logInViaBrowser;

  /// Lead text before a register link; trailing space keeps spacing before the link.
  ///
  /// In en, this message translates to:
  /// **'Need an account? '**
  String get needAccountPrompt;

  /// Generic label to create a new account.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// Divider between alternative actions (e.g. email login vs SSO).
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get orDivider;

  /// Title for the captcha verification modal.
  ///
  /// In en, this message translates to:
  /// **'Verify you\'re human'**
  String get captchaTitle;

  /// Explanatory text in the captcha modal body.
  ///
  /// In en, this message translates to:
  /// **'We need to make sure you\'re not a bot. Please complete the verification below.'**
  String get captchaDescription;

  /// Link to switch from Turnstile to hCaptcha provider.
  ///
  /// In en, this message translates to:
  /// **'Having issues? Try hCaptcha instead'**
  String get captchaSwitchToHcaptcha;

  /// Link to switch from hCaptcha to Turnstile provider.
  ///
  /// In en, this message translates to:
  /// **'Try Turnstile instead'**
  String get captchaSwitchToTurnstile;

  /// Generic cancel action label.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Title when IP authorization email has been sent.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get ipAuthCheckEmail;

  /// Description telling the user to check their email for IP auth.
  ///
  /// In en, this message translates to:
  /// **'We emailed a link to authorize this login. Please open your inbox for {email}.'**
  String ipAuthDescription(String email);

  /// Title when polling for IP authorization fails.
  ///
  /// In en, this message translates to:
  /// **'Connection lost'**
  String get ipAuthConnectionLost;

  /// Description when IP authorization polling fails.
  ///
  /// In en, this message translates to:
  /// **'We lost the connection while waiting for authorization. Please try again.'**
  String get ipAuthConnectionLostDescription;

  /// Button to resend the IP authorization email.
  ///
  /// In en, this message translates to:
  /// **'Resend email'**
  String get ipAuthResendEmail;

  /// Button label after IP authorization email has been resent.
  ///
  /// In en, this message translates to:
  /// **'Resent'**
  String get ipAuthResent;

  /// Countdown suffix for the resend button cooldown.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String ipAuthResendCountdown(int seconds);

  /// Generic back navigation label.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Title for the MFA challenge screen.
  ///
  /// In en, this message translates to:
  /// **'Two-factor authentication'**
  String get mfaTitle;

  /// Description text when multiple MFA methods are available.
  ///
  /// In en, this message translates to:
  /// **'Choose a verification method'**
  String get mfaChooseMethod;

  /// Label for the TOTP authenticator method.
  ///
  /// In en, this message translates to:
  /// **'Authenticator App'**
  String get mfaMethodTotp;

  /// Label for the SMS code method.
  ///
  /// In en, this message translates to:
  /// **'SMS Code'**
  String get mfaMethodSms;

  /// Label for the WebAuthn security key method.
  ///
  /// In en, this message translates to:
  /// **'Security Key / Passkey'**
  String get mfaMethodWebauthn;

  /// Description for the TOTP code entry screen.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code from your authenticator app or one of your backup codes.'**
  String get mfaTotpDescription;

  /// Description for the SMS code entry screen.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to your phone.'**
  String get mfaSmsDescription;

  /// Button label to send an SMS verification code.
  ///
  /// In en, this message translates to:
  /// **'Send SMS Code'**
  String get mfaSendSmsCode;

  /// Label for the MFA code input field.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get mfaCodeLabel;

  /// Link to switch to a different MFA method.
  ///
  /// In en, this message translates to:
  /// **'Try another method'**
  String get mfaTryAnotherMethod;

  /// Link to switch to WebAuthn from code entry.
  ///
  /// In en, this message translates to:
  /// **'Try security key / passkey instead'**
  String get mfaUseSecurityKey;

  /// Title for the account selector on the login screen.
  ///
  /// In en, this message translates to:
  /// **'Choose an account'**
  String get accountSelectorTitle;

  /// Description for the account selector.
  ///
  /// In en, this message translates to:
  /// **'Select an account to continue, or add a different one.'**
  String get accountSelectorDescription;

  /// Button to add a new account.
  ///
  /// In en, this message translates to:
  /// **'Add an account'**
  String get accountAdd;

  /// Context menu option to remove a stored account.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get accountRemove;

  /// Title for the remove account confirmation modal.
  ///
  /// In en, this message translates to:
  /// **'Remove {username}'**
  String accountRemoveTitle(String username);

  /// Description for the remove account confirmation modal.
  ///
  /// In en, this message translates to:
  /// **'This will remove the saved session for this account.'**
  String get accountRemoveDescription;

  /// Description when removing the last stored account.
  ///
  /// In en, this message translates to:
  /// **'This will remove the only saved account on this device.'**
  String get accountRemoveOnlyDescription;

  /// Label shown on accounts with expired sessions.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get accountExpired;

  /// Message when selecting an expired account.
  ///
  /// In en, this message translates to:
  /// **'Session expired for {identifier}. Please log in again.'**
  String accountSessionExpired(String identifier);

  /// Badge shown on the currently active account.
  ///
  /// In en, this message translates to:
  /// **'Active account'**
  String get accountActive;

  /// Context menu option to sign out of current account.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// Title when account is permanently banned.
  ///
  /// In en, this message translates to:
  /// **'Account Permanently Suspended'**
  String get suspendedPermanentTitle;

  /// Title when account is temporarily suspended.
  ///
  /// In en, this message translates to:
  /// **'Account Suspended'**
  String get suspendedTemporaryTitle;

  /// Description for permanent suspension.
  ///
  /// In en, this message translates to:
  /// **'Your account has been permanently suspended for violating our Terms of Service.'**
  String get suspendedPermanentDescription;

  /// Description for temporary suspension.
  ///
  /// In en, this message translates to:
  /// **'Your account has been temporarily suspended. You will be able to access your account once the suspension period ends.'**
  String get suspendedTemporaryDescription;

  /// Label for when the ban was issued.
  ///
  /// In en, this message translates to:
  /// **'Issued'**
  String get suspendedIssuedAt;

  /// Label for when a temporary ban ends.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get suspendedEndsAt;

  /// Label for ban duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get suspendedDuration;

  /// Value shown for permanent ban duration.
  ///
  /// In en, this message translates to:
  /// **'Permanent'**
  String get suspendedPermanent;

  /// Label for ban reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get suspendedReason;

  /// Label for appeal deadline date.
  ///
  /// In en, this message translates to:
  /// **'Appeal Deadline'**
  String get suspendedAppealDeadline;

  /// Warning about scheduled account deletion.
  ///
  /// In en, this message translates to:
  /// **'Your account is scheduled for deletion on {date}.'**
  String suspendedDeletionWarning(String date);

  /// Button to recheck ban status.
  ///
  /// In en, this message translates to:
  /// **'Check for Updates'**
  String get suspendedRecheck;

  /// Recheck button with cooldown timer.
  ///
  /// In en, this message translates to:
  /// **'Check again in {seconds}s'**
  String suspendedRecheckCooldown(int seconds);

  /// Button to return to login screen.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get suspendedBackToLogin;

  /// Title for the appeal section.
  ///
  /// In en, this message translates to:
  /// **'Appeal'**
  String get suspendedAppealTitle;

  /// Placeholder text for the appeal textarea.
  ///
  /// In en, this message translates to:
  /// **'Explain why your suspension should be reconsidered (minimum 50 characters)...'**
  String get suspendedAppealHint;

  /// Button to submit an appeal.
  ///
  /// In en, this message translates to:
  /// **'Submit Appeal'**
  String get suspendedAppealSubmit;

  /// Badge for appeal with pending status.
  ///
  /// In en, this message translates to:
  /// **'Pending Review'**
  String get suspendedAppealPending;

  /// Badge for accepted appeal.
  ///
  /// In en, this message translates to:
  /// **'Appeal Accepted'**
  String get suspendedAppealAccepted;

  /// Badge for rejected appeal.
  ///
  /// In en, this message translates to:
  /// **'Appeal Rejected'**
  String get suspendedAppealRejected;

  /// Message when appeal is accepted.
  ///
  /// In en, this message translates to:
  /// **'Your appeal has been accepted and your account has been reinstated.'**
  String get suspendedAppealAcceptedDescription;

  /// Button to sign in after appeal is accepted.
  ///
  /// In en, this message translates to:
  /// **'Sign In to Your Account'**
  String get suspendedSignIn;

  /// Title for the forgot password screen.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get forgotPasswordTitle;

  /// Description for the forgot password screen.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address and we\'ll send you a link to reset your password.'**
  String get forgotPasswordDescription;

  /// Button to submit the forgot password form.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get forgotPasswordSubmit;

  /// Title after forgot password email is sent.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get forgotPasswordSentTitle;

  /// Description after forgot password email is sent.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent password reset instructions to your email address. Please check your inbox and follow the link to reset your password.'**
  String get forgotPasswordSentDescription;

  /// Link to go back to login from forgot password.
  ///
  /// In en, this message translates to:
  /// **'Return to login'**
  String get forgotPasswordBackToLogin;

  /// Title for the reset password screen.
  ///
  /// In en, this message translates to:
  /// **'Set new password'**
  String get resetPasswordTitle;

  /// Description for the reset password screen.
  ///
  /// In en, this message translates to:
  /// **'Enter your new password below to complete the reset process.'**
  String get resetPasswordDescription;

  /// Label for the new password field.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get resetPasswordNewPassword;

  /// Label for the confirm password field.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get resetPasswordConfirm;

  /// Button to submit the password reset form.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPasswordSubmit;

  /// Error when password and confirmation don't match.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get resetPasswordMismatch;

  /// Title for the registration screen.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get registerTitle;

  /// Label for the display name field.
  ///
  /// In en, this message translates to:
  /// **'Display Name (Optional)'**
  String get registerDisplayName;

  /// Hint for the display name field.
  ///
  /// In en, this message translates to:
  /// **'What should people call you?'**
  String get registerDisplayNameHint;

  /// Label for the username field.
  ///
  /// In en, this message translates to:
  /// **'Username (Optional)'**
  String get registerUsername;

  /// Hint for the username field.
  ///
  /// In en, this message translates to:
  /// **'Leave blank for a random username'**
  String get registerUsernameHint;

  /// Helper text shown below the username field explaining automatic tag generation.
  ///
  /// In en, this message translates to:
  /// **'A 4-digit tag will be added automatically to ensure uniqueness'**
  String get registerUsernameTagHint;

  /// Label for the date of birth field.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get registerDateOfBirth;

  /// Placeholder for the month select.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get registerMonth;

  /// Placeholder for the day select.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get registerDay;

  /// Placeholder for the year select.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get registerYear;

  /// Consent checkbox label for registration (plain text fallback).
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms of Service and Privacy Policy'**
  String get registerConsent;

  /// Text before the Terms of Service link in the consent checkbox.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get registerConsentPrefix;

  /// Terms of Service link text in the consent checkbox.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get registerConsentTerms;

  /// Conjunction between Terms and Privacy links.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get registerConsentAnd;

  /// Privacy Policy link text in the consent checkbox.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get registerConsentPrivacy;

  /// Label for the confirm password field on the register screen.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get registerConfirmPassword;

  /// Button to submit the registration form.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerSubmit;

  /// Text before the login link on the register screen.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get registerHaveAccount;

  /// Error when user has no passkeys registered and tries passkey login.
  ///
  /// In en, this message translates to:
  /// **'No passkeys found for this app. Log in with email and password instead.'**
  String get passkeyNoCredentials;

  /// Error when device does not support passkeys.
  ///
  /// In en, this message translates to:
  /// **'Passkeys are not supported on this device.'**
  String get passkeyDeviceNotSupported;

  /// Error when passkey domain association is missing.
  ///
  /// In en, this message translates to:
  /// **'Passkeys are not configured for this app. Log in with email and password instead.'**
  String get passkeyDomainNotAssociated;

  /// Error when passkey authentication times out.
  ///
  /// In en, this message translates to:
  /// **'Passkey authentication timed out. Please try again.'**
  String get passkeyTimeout;

  /// Error for unknown passkey provider errors (e.g. TYPE_UNKNOWN).
  ///
  /// In en, this message translates to:
  /// **'Passkeys are not available for this app. Log in with email and password instead.'**
  String get passkeyNotAvailable;

  /// Generic fallback error for passkey authentication.
  ///
  /// In en, this message translates to:
  /// **'Passkey authentication failed. Please try again.'**
  String get passkeyFailed;

  /// Generic fallback error when registration fails unexpectedly.
  ///
  /// In en, this message translates to:
  /// **'Unable to create account. Please try again.'**
  String get errorUnableToCreateAccount;

  /// Generic fallback error when login fails unexpectedly.
  ///
  /// In en, this message translates to:
  /// **'Unable to sign in right now. Please try again.'**
  String get errorUnableToSignIn;

  /// Generic fallback error when forgot password request fails.
  ///
  /// In en, this message translates to:
  /// **'Unable to send reset link. Please try again.'**
  String get errorUnableToSendResetLink;

  /// Generic fallback error when password reset fails unexpectedly.
  ///
  /// In en, this message translates to:
  /// **'Unable to reset password. Please try again.'**
  String get errorUnableToResetPassword;

  /// Button to join a guild from an invite embed card.
  ///
  /// In en, this message translates to:
  /// **'Join Community'**
  String get embedInviteJoin;

  /// Button when user is already a member of the guild.
  ///
  /// In en, this message translates to:
  /// **'Go to Community'**
  String get embedInviteGoTo;

  /// Online member count on the invite embed card.
  ///
  /// In en, this message translates to:
  /// **'{count} Online'**
  String embedInviteOnline(String count);

  /// Total member count on the invite embed card.
  ///
  /// In en, this message translates to:
  /// **'{count} Members'**
  String embedInviteMembers(String count);

  /// Title when an invite is expired or invalid.
  ///
  /// In en, this message translates to:
  /// **'Unknown Invite'**
  String get embedInviteUnknownTitle;

  /// Subtitle when an invite is expired or invalid.
  ///
  /// In en, this message translates to:
  /// **'Try asking for a new invite.'**
  String get embedInviteUnknownSubtitle;

  /// Disabled button label when an invite is unavailable.
  ///
  /// In en, this message translates to:
  /// **'Invite Unavailable'**
  String get embedInviteUnavailable;

  /// Fallback name shown in a channel mention pill when the channel is not found.
  ///
  /// In en, this message translates to:
  /// **'unknown-channel'**
  String get mentionUnknownChannel;

  /// Title of the modal shown when clicking a jump link to an inaccessible channel.
  ///
  /// In en, this message translates to:
  /// **'Channel Access Denied'**
  String get channelAccessDeniedTitle;

  /// Body of the channel access denied modal.
  ///
  /// In en, this message translates to:
  /// **'You do not have access to the channel where this message was sent.'**
  String get channelAccessDeniedDescription;

  /// Generic confirmation button label.
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get okay;

  /// Title on the theme embed card in chat.
  ///
  /// In en, this message translates to:
  /// **'Shared theme'**
  String get embedThemeTitle;

  /// Subtitle on the theme embed card.
  ///
  /// In en, this message translates to:
  /// **'This client doesn\'t support custom themes.'**
  String get embedThemeSubtitle;

  /// Button on the theme embed card - themes aren't supported in the client.
  ///
  /// In en, this message translates to:
  /// **'Themes unavailable'**
  String get embedThemeUnavailableButton;
}

class _FluxerLocalizationsDelegate
    extends LocalizationsDelegate<FluxerLocalizations> {
  const _FluxerLocalizationsDelegate();

  @override
  Future<FluxerLocalizations> load(Locale locale) {
    return SynchronousFuture<FluxerLocalizations>(
      lookupFluxerLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_FluxerLocalizationsDelegate old) => false;
}

FluxerLocalizations lookupFluxerLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return FluxerLocalizationsEn();
  }

  throw FlutterError(
    'FluxerLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
