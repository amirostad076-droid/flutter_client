// Constructor parameters are required by the interface but unused in the stub.
// ignore_for_file: avoid_unused_constructor_parameters

import 'package:flutter/material.dart';
import 'package:fluxer_captcha/src/captcha_provider.dart';
import 'package:fluxer_captcha/src/controller/captcha_controller.dart';
import 'package:fluxer_captcha/src/widget/captcha_options.dart';
import 'package:fluxer_captcha/src/widget/interface.dart' as i;

/// Facade class for FluxerCaptcha.
class FluxerCaptcha extends StatelessWidget implements i.FluxerCaptcha {
  /// Create a FluxerCaptcha widget.
  ///
  /// The [provider] selects the captcha backend (Turnstile or hCaptcha).
  /// The [siteKey] is required and associates this widget with a captcha
  /// instance. Additional parameters like [action], [cData], [controller],
  /// and various options customize the widget's behavior.
  FluxerCaptcha({
    required this.provider,
    required this.siteKey,
    super.key,
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

  /// Create an invisible captcha widget.
  ///
  /// [provider] - The captcha provider to use.
  ///
  /// [siteKey] - A captcha sitekey.
  ///
  /// [action] - A customer value that can be used to differentiate widgets
  /// under the same sitekey in analytics and which is returned upon
  /// validation. Turnstile only.
  ///
  /// [cData] - A customer payload that can be used to attach customer data
  /// to the challenge throughout its issuance and which is returned upon
  /// validation. Turnstile only.
  ///
  /// [baseUrl] - A website URL corresponding to the current captcha widget.
  ///
  /// [options] - Configuration options for the captcha widget.
  ///
  /// [onTokenReceived] - A callback invoked upon success of the challenge.
  /// The callback is passed a `token` that can be validated.
  ///
  /// [onTokenExpired] - A callback invoked when the token expires and does
  /// not reset the widget.
  factory FluxerCaptcha.invisible({
    required CaptchaProvider provider,
    required String siteKey,
    String? action,
    String? cData,
    String baseUrl = 'http://localhost',
    CaptchaOptions? options,
    i.OnTokenReceived? onTokenReceived,
    i.OnTokenExpired? onTokenExpired,
    i.OnTimeout? onTimeout,
  }) {
    throw UnimplementedError(
      'Cannot call this method on the facade implementation of FluxerCaptcha.',
    );
  }

  /// The captcha provider to use.
  @override
  final CaptchaProvider provider;

  /// This [siteKey] is associated with the corresponding widget configuration
  /// and is created upon the widget creation.
  @override
  final String siteKey;

  /// A customer value that can be used to differentiate widgets under the
  /// same sitekey in analytics and which is returned upon validation.
  ///
  /// This can only contain up to 32 alphanumeric characters including _ and -.
  /// Turnstile only.
  @override
  final String? action;

  /// A customer payload that can be used to attach customer data to the
  /// challenge throughout its issuance and which is returned upon validation.
  ///
  /// This can only contain up to 255 alphanumeric characters including _ and -.
  /// Turnstile only.
  @override
  final String? cData;

  /// The base URL of the captcha site.
  ///
  /// Defaults to 'http://localhost/'.
  @override
  final String baseUrl;

  /// Configuration options for the captcha widget.
  ///
  /// If no options are provided, the default [CaptchaOptions] are used.
  @override
  final CaptchaOptions? options;

  /// A controller for managing interactions with the captcha widget.
  @override
  final CaptchaController? controller;

  /// A callback invoked upon success of the challenge.
  /// The callback is passed a `token` that can be validated.
  @override
  final i.OnTokenReceived? onTokenReceived;

  /// A callback invoked when the token expires and does not reset the widget.
  @override
  final i.OnTokenExpired? onTokenExpired;

  /// A callback invoked when there is an error
  /// (e.g., network error or challenge failed).
  @override
  final i.OnError? onError;

  /// Callback invoked when the captcha widget fails to load in time.
  @override
  final i.OnTimeout? onTimeout;

  /// Retrieves the current token from the widget.
  ///
  /// Returns `null` if no token is available.
  @override
  String? get token => throw UnimplementedError(
        'Cannot call this method on the facade implementation of '
        'FluxerCaptcha.',
      );

  /// Retrieves the current widget id.
  ///
  /// This `id` is used to uniquely identify the captcha widget instance.
  @override
  String? get id => throw UnimplementedError(
        'Cannot call this method on the facade implementation of '
        'FluxerCaptcha.',
      );

  /// Refreshes the captcha challenge.
  @override
  Future<void> refresh({bool forceRefresh = true}) {
    throw UnimplementedError(
      'Cannot call this method on the facade implementation of FluxerCaptcha.',
    );
  }

  /// Starts a captcha challenge and returns a token, or `null` if the
  /// challenge failed or an error occurred.
  @override
  Future<String?> getToken() {
    throw UnimplementedError(
      'Cannot call this method on the facade implementation of FluxerCaptcha.',
    );
  }

  /// Checks if the captcha widget has expired.
  @override
  Future<bool> isExpired() {
    throw UnimplementedError(
      'Cannot call this method on the facade implementation of FluxerCaptcha.',
    );
  }

  /// Disposes the captcha widget and frees up resources.
  @override
  Future<void> dispose() {
    throw UnimplementedError(
      'Cannot call this method on the facade implementation of FluxerCaptcha.',
    );
  }

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError(
      'Cannot call this method on the facade implementation of FluxerCaptcha.',
    );
  }
}
