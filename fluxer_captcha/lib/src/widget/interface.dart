import 'package:fluxer_captcha/src/captcha_exception.dart';
import 'package:fluxer_captcha/src/captcha_provider.dart';
import 'package:fluxer_captcha/src/controller/captcha_controller.dart';
import 'package:fluxer_captcha/src/widget/captcha_options.dart';

/// Callback invoked upon successful token reception.
typedef OnTokenReceived = void Function(String token);

/// Callback invoked when the token expires. Does not reset the widget.
typedef OnTokenExpired = void Function();

/// Callback invoked when an error occurs during the captcha challenge.
typedef OnError = void Function(CaptchaException error);

/// Callback invoked when the captcha widget fails to load within a timeout.
typedef OnTimeout = void Function();

/// Abstract captcha widget supporting Cloudflare Turnstile and hCaptcha.
abstract class FluxerCaptcha {
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

  final CaptchaProvider provider;

  /// The sitekey associated with this widget's configuration.
  final String siteKey;

  /// Analytics differentiator returned upon validation. Max 32 alphanumeric
  /// characters including _ and -. Turnstile only.
  final String? action;

  /// Customer payload attached to the challenge and returned upon validation.
  /// Max 255 alphanumeric characters including _ and -. Turnstile only.
  final String? cData;

  /// The base URL of the captcha site.
  final String baseUrl;

  /// Configuration options for the captcha widget.
  final CaptchaOptions? options;

  /// Controller for managing interactions with the captcha widget.
  final CaptchaController? controller;

  final OnTokenReceived? onTokenReceived;
  final OnTokenExpired? onTokenExpired;
  final OnError? onError;
  final OnTimeout? onTimeout;

  /// The current captcha token, or `null` if unavailable.
  String? get token;

  /// The captcha widget instance ID.
  String? get id;

  /// Refreshes the captcha challenge.
  ///
  /// Can only be called when [id] is not null.
  Future<void> refresh({bool forceRefresh = true});

  /// Starts a captcha challenge and returns a token, or `null` on failure.
  Future<String?> getToken();

  /// Checks if the captcha widget has expired.
  ///
  /// Can only be called when [id] is not null.
  Future<bool> isExpired();

  /// Disposes the captcha widget and frees resources.
  Future<void> dispose();
}
