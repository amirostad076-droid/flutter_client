import 'package:cloudflare_turnstile/cloudflare_turnstile.dart';
import 'package:flutter/material.dart';

import 'package:fluxeron/core/theme/fluxer_colors.dart';

/// Dialog that shows a visible Cloudflare Turnstile captcha widget.
///
/// Returns the captcha token via [Navigator.pop] on success, or `null`
/// if dismissed.
class CaptchaDialog extends StatelessWidget {
  const CaptchaDialog({
    required this.siteKey,
    required this.baseUrl,
    super.key,
  });

  final String siteKey;
  final String baseUrl;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: FluxerColors.backgroundSecondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Verify you are human',
              style: TextStyle(
                color: FluxerColors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            CloudflareTurnstile(
              siteKey: siteKey,
              baseUrl: baseUrl,
              options: TurnstileOptions(theme: TurnstileTheme.dark),
              onTokenReceived: (token) {
                Navigator.of(context).pop(token);
              },
              onError: (_) {
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: FluxerColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows a [CaptchaDialog] using the given navigator key and returns the token.
Future<String?> showCaptchaDialog({
  required GlobalKey<NavigatorState> navigatorKey,
  required String siteKey,
  required String baseUrl,
}) {
  final context = navigatorKey.currentState?.context;
  if (context == null) {
    return Future<String?>.value();
  }

  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (_) => CaptchaDialog(siteKey: siteKey, baseUrl: baseUrl),
  );
}
