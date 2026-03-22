import 'package:flutter/material.dart';

/// Configuration options for the captcha widget.
///
/// Supports both Cloudflare Turnstile and hCaptcha. Fields marked as
/// "Turnstile-only" are ignored when using hCaptcha.
class CaptchaOptions {
  /// Creates a captcha options configuration.
  CaptchaOptions({
    this.size = CaptchaSize.normal,
    this.theme = CaptchaTheme.auto,
    this.language = 'auto',
    this.retryAutomatically = true,
    this.retryInterval = const Duration(milliseconds: 8000),
    this.refreshExpired = CaptchaRefreshExpired.auto,
    this.refreshTimeout = CaptchaRefreshTimeout.auto,
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
    this.animationDuration = const Duration(milliseconds: 500),
    this.curves = Curves.linearToEaseOut,
  });

  /// The widget size.
  ///
  /// Can be set to [CaptchaSize.normal], [CaptchaSize.compact], or
  /// [CaptchaSize.flexible].
  /// The default value is [CaptchaSize.normal].
  final CaptchaSize size;

  /// The theme of the widget.
  ///
  /// Defaults to [CaptchaTheme.auto], which automatically adjusts based on
  /// the device's brightness setting. Can also be set to [CaptchaTheme.dark]
  /// or [CaptchaTheme.light].
  CaptchaTheme theme;

  /// The language to display in the widget.
  ///
  /// Defaults to 'auto', which uses the language chosen by the visitor.
  /// You can set an ISO 639-1 two-letter language code (e.g., 'en' for
  /// English), or a language and country code (e.g., 'en-US').
  final String language;

  /// Whether the widget should automatically retry obtaining a token if
  /// the challenge fails.
  ///
  /// Defaults to `true`, which enables automatic retry. Set to `false` to
  /// disable automatic retry on failure.
  ///
  /// Ignored for hCaptcha.
  final bool retryAutomatically;

  /// The interval between retry attempts when [retryAutomatically] is enabled.
  ///
  /// The value is specified as a [Duration], with the default being 8 seconds
  /// (8000 milliseconds). This value must be a positive integer and less than
  /// 900000 milliseconds (15 minutes).
  ///
  /// Ignored for hCaptcha.
  final Duration retryInterval;

  /// Behavior for refreshing the token when it expires.
  ///
  /// Can be set to [CaptchaRefreshExpired.auto],
  /// [CaptchaRefreshExpired.manual], or [CaptchaRefreshExpired.never].
  ///
  /// The default is [CaptchaRefreshExpired.auto], which refreshes the token
  /// automatically when it expires.
  ///
  /// Ignored for hCaptcha.
  final CaptchaRefreshExpired refreshExpired;

  /// Controls how the widget behaves when a timeout occurs during an
  /// interactive challenge.
  ///
  /// Can be set to [CaptchaRefreshTimeout.auto] (automatic refresh),
  /// [CaptchaRefreshTimeout.manual] (manual refresh by the visitor), or
  /// [CaptchaRefreshTimeout.never] (show a timeout without refreshing).
  /// The default is [CaptchaRefreshTimeout.auto].
  ///
  /// Ignored for hCaptcha.
  final CaptchaRefreshTimeout refreshTimeout;

  /// The border radius applied to the widget.
  ///
  /// This allows customization of the widget's appearance by rounding the
  /// corners. The default is a circular radius of 4 pixels.
  final BorderRadiusGeometry? borderRadius;

  /// The duration of animations when displaying the widget.
  ///
  /// This defines how long animations take to complete.
  /// The default value is 500 milliseconds.
  final Duration? animationDuration;

  /// The curve applied to animations when displaying the widget.
  ///
  /// This allows for different animation styles during the display.
  /// The default is [Curves.linearToEaseOut].
  final Curve? curves;
}

/// Defines the sizes for the captcha widget.
enum CaptchaSize {
  /// Normal size for the widget.
  ///
  /// Dimensions: width 300px, height 65px.
  normal(300, 65),

  /// Compact size for the widget.
  ///
  /// Dimensions: width 150px, height 140px.
  compact(150, 140),

  /// Flexible size for the widget.
  ///
  /// Width is flexible (min 300px), and height is fixed at 65px.
  flexible(double.maxFinite, 65);

  /// Creates a [CaptchaSize] with the specified [width] and [height].
  const CaptchaSize(
    this.width,
    this.height,
  );

  /// The width of the widget.
  final double width;

  /// The height of the widget.
  final double height;
}

/// Defines the themes for the captcha widget.
enum CaptchaTheme {
  /// Automatic theme.
  ///
  /// The theme is automatically selected based on the context.
  auto,

  /// Dark theme.
  ///
  /// The widget uses a dark theme.
  dark,

  /// Light theme.
  ///
  /// The widget uses a light theme.
  light,
}

/// Defines the refresh behavior when the token expires.
///
/// Applies to Cloudflare Turnstile only.
enum CaptchaRefreshExpired {
  /// Automatic refresh.
  ///
  /// The widget automatically refreshes when the token expires.
  auto,

  /// Manual refresh.
  ///
  /// The widget requires manual refresh when the token expires.
  manual,

  /// Never refresh.
  ///
  /// The widget does not refresh when the token expires.
  never,
}

/// Defines the refresh behavior when the token times out.
///
/// Applies to Cloudflare Turnstile only.
enum CaptchaRefreshTimeout {
  /// Automatic refresh.
  ///
  /// The widget automatically refreshes when the token times out.
  auto,

  /// Manual refresh.
  ///
  /// The widget requires manual refresh when the token times out.
  manual,

  /// Never refresh.
  ///
  /// The widget does not refresh when the token times out.
  never,
}
