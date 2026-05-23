import 'package:flutter/widgets.dart';
import 'package:fluxer_captcha/src/widget/captcha_options.dart';

/// Resolved styling values for the captcha widget.
class CaptchaStyling {
  const CaptchaStyling({
    required this.resolvedTheme,
    required this.primaryColor,
    required this.secondaryColor,
  });

  /// Resolves auto theme and computes colors for the captcha widget.
  factory CaptchaStyling.resolve(
    CaptchaOptions options,
    Brightness brightness,
  ) {
    final resolvedTheme = options.theme == CaptchaTheme.auto
        ? (brightness == Brightness.dark
              ? CaptchaTheme.dark
              : CaptchaTheme.light)
        : options.theme;

    return CaptchaStyling(
      resolvedTheme: resolvedTheme,
      primaryColor: resolvedTheme == CaptchaTheme.light
          ? const Color(0xFFFAFAFA)
          : const Color(0xFF232323),
      secondaryColor: resolvedTheme == CaptchaTheme.light
          ? const Color(0xFFDEDEDE)
          : const Color(0xFF9A9A9A),
    );
  }

  /// The resolved theme (never [CaptchaTheme.auto]).
  final CaptchaTheme resolvedTheme;

  /// Background color for the captcha container.
  final Color primaryColor;

  /// Border color for the captcha container.
  final Color secondaryColor;
}
