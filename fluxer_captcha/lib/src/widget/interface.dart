import 'package:fluxer_captcha/src/captcha_exception.dart';
import 'package:fluxer_captcha/src/captcha_provider.dart';
import 'package:fluxer_captcha/src/controller/captcha_controller.dart';
import 'package:fluxer_captcha/src/widget/captcha_options.dart';

/// Callback invoked upon successful token reception.
///
/// The callback receives a [token] that can be validated.
typedef OnTokenReceived = void Function(String token);

/// Callback invoked when the token expires.
///
/// The callback does not reset the widget.
typedef OnTokenExpired = void Function();

/// Callback invoked when an error occurs.
///
/// The callback receives a [CaptchaException] object, [error], which provides
/// details about the error, such as network issues or a challenge failure.
typedef OnError = void Function(CaptchaException error);

/// Callback invoked when the captcha widget fails to load within a timeout.
///
/// This can be used to trigger a fallback flow (e.g., enable an alternative
/// verification method) if the captcha script is unavailable or delayed.
typedef OnTimeout = void Function();

/// Abstract class representing a captcha widget.
///
/// Supports both Cloudflare Turnstile and hCaptcha via [CaptchaProvider].
abstract class FluxerCaptcha {
  /// Creates a captcha widget.
  ///
  /// The [provider] selects the captcha backend (Turnstile or hCaptcha).
  /// The [siteKey] is required and associates this widget with a captcha
  /// instance. Additional parameters like [action], [cData], [controller],
  /// and various options customize the widget's behavior.
  FluxerCaptcha({
    required this.provider,
    required this.siteKey,
    this.action,
    this.cData,
    this.baseUrl = 'http://localhost/',
    CaptchaOptions? options,
    this.controller,
    this.onTokenReceived,
    this.onTokenExpired,
    this.onError,
    this.onTimeout,
  }) : options = options ?? CaptchaOptions();

  /// The captcha provider to use.
  final CaptchaProvider provider;

  /// This [siteKey] is associated with the corresponding widget configuration
  /// and is created upon the widget creation.
  final String siteKey;

  /// A customer value that can be used to differentiate widgets under the
  /// same sitekey in analytics and which is returned upon validation.
  ///
  /// This can only contain up to 32 alphanumeric characters including _ and -.
  final String? action;

  /// A customer payload that can be used to attach customer data to the
  /// challenge throughout its issuance and which is returned upon validation.
  ///
  /// This can only contain up to 255 alphanumeric characters including _ and -.
  final String? cData;

  /// The base URL of the captcha site.
  ///
  /// Defaults to 'http://localhost/'.
  final String baseUrl;

  /// Configuration options for the captcha widget.
  ///
  /// If no options are provided, the default [CaptchaOptions] are used.
  final CaptchaOptions? options;

  /// A controller for managing interactions with the captcha widget.
  final CaptchaController? controller;

  /// A callback invoked upon success of the challenge.
  /// The callback is passed a `token` that can be validated.
  final OnTokenReceived? onTokenReceived;

  /// A callback invoked when the token expires and does not reset the widget.
  final OnTokenExpired? onTokenExpired;

  /// A callback invoked when there is an error
  /// (e.g., network error or challenge failed).
  final OnError? onError;

  /// Callback invoked when the captcha widget fails to load in time.
  final OnTimeout? onTimeout;

  /// Retrieves the current token from the widget.
  ///
  /// Returns `null` if no token is available.
  String? get token;

  /// Retrieves the current widget id.
  ///
  /// This `id` is used to uniquely identify the captcha widget instance.
  String? get id;

  /// Refreshes the captcha challenge. If the widget may have become expired,
  /// this will start a new challenge.
  ///
  /// This method can only be called when [id] is not null.
  Future<void> refresh({bool forceRefresh = true});

  /// Starts a captcha challenge and returns a token, or `null` if the
  /// challenge failed or an error occurred.
  Future<String?> getToken();

  /// Checks if the captcha widget has expired.
  ///
  /// This method can only be called when [id] is not null.
  Future<bool> isExpired();

  /// Disposes the captcha widget and frees up resources.
  Future<void> dispose();
}
