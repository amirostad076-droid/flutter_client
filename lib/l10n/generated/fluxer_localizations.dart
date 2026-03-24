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
