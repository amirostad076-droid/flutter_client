import 'dart:async';
import 'dart:convert';

import 'package:cloudflare_turnstile/cloudflare_turnstile.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Error codes the Fluxer API returns when captcha verification is needed.
const _kCaptchaCodes = {'CAPTCHA_REQUIRED', 'INVALID_CAPTCHA'};

/// Captcha configuration extracted from the `.well-known/fluxer` response.
class _CaptchaConfig {
  const _CaptchaConfig({
    required this.provider,
    required this.siteKey,
    required this.baseUrl,
  });

  final String provider;
  final String siteKey;

  /// The webapp URL used as the WebView origin so Cloudflare Turnstile
  /// recognises the domain against the site key's allowed origins.
  final String baseUrl;
}

/// Dio interceptor that handles captcha challenges from the Fluxer API.
///
/// When a response with code `CAPTCHA_REQUIRED` or `INVALID_CAPTCHA` is
/// received, the interceptor:
/// 1. Fetches the instance captcha config from `/.well-known/fluxer`.
/// 2. Attempts to solve the challenge via Turnstile invisible mode.
/// 3. If invisible mode fails, shows a visible captcha dialog.
/// 4. Retries the original request with `X-Captcha-Token` and
///    `X-Captcha-Type` headers.
class CaptchaInterceptor extends Interceptor {
  CaptchaInterceptor({required this.dio, required this.showCaptchaDialog});

  /// The Dio instance used to retry requests and fetch captcha config.
  final Dio dio;

  /// Callback that shows a visible Turnstile dialog and returns
  /// the token. Used as fallback when invisible mode fails.
  final Future<String?> Function({
    required String siteKey,
    required String baseUrl,
  })
  showCaptchaDialog;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;
    if (response == null || response.statusCode != 400) {
      handler.next(err);
      return;
    }

    final code = _extractErrorCode(response);
    if (code == null || !_kCaptchaCodes.contains(code)) {
      handler.next(err);
      return;
    }

    unawaited(_solveCaptchaAndRetry(err, handler));
  }

  Future<void> _solveCaptchaAndRetry(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    try {
      final config = await _fetchCaptchaConfig();
      if (config == null) {
        handler.next(err);
        return;
      }

      var token = await _solveInvisible(
        siteKey: config.siteKey,
        baseUrl: config.baseUrl,
      );
      token ??= await showCaptchaDialog(
        siteKey: config.siteKey,
        baseUrl: config.baseUrl,
      );

      if (token == null || token.isEmpty) {
        handler.next(err);
        return;
      }

      final opts = err.requestOptions;
      opts.headers['X-Captcha-Token'] = token;
      opts.headers['X-Captcha-Type'] = config.provider;

      final retryResponse = await dio.fetch<dynamic>(opts);
      handler.resolve(retryResponse);
    } on DioException catch (retryError) {
      handler.next(retryError);
    } on Exception {
      handler.next(err);
    }
  }

  Future<_CaptchaConfig?> _fetchCaptchaConfig() async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/.well-known/fluxer',
      );
      final data = response.data;
      if (data == null) {
        return null;
      }

      final captcha = data['captcha'] as Map<String, dynamic>?;
      if (captcha == null) {
        return null;
      }

      final provider = captcha['provider'] as String? ?? 'none';
      if (provider == 'none') {
        return null;
      }

      String? siteKey;
      if (provider == 'turnstile') {
        siteKey = captcha['turnstile_site_key'] as String?;
      } else if (provider == 'hcaptcha') {
        siteKey = captcha['hcaptcha_site_key'] as String?;
      }

      if (siteKey == null || siteKey.isEmpty) {
        return null;
      }

      // Use the webapp endpoint as the WebView base URL so the
      // page origin matches the Turnstile site key's allowed
      // domains.
      final endpoints = data['endpoints'] as Map<String, dynamic>?;
      final baseUrl = endpoints?['webapp'] as String? ?? 'http://localhost';

      return _CaptchaConfig(
        provider: provider,
        siteKey: siteKey,
        baseUrl: baseUrl,
      );
    } on Exception {
      return null;
    }
  }

  Future<String?> _solveInvisible({
    required String siteKey,
    required String baseUrl,
  }) async {
    // Invisible mode uses a headless WebView — not available on web.
    if (kIsWeb) {
      return null;
    }

    CloudflareTurnstile? turnstile;
    try {
      turnstile = CloudflareTurnstile.invisible(
        siteKey: siteKey,
        baseUrl: baseUrl,
      );
      final token = await turnstile.getToken();
      return token;
    } on Exception {
      return null;
    } finally {
      await turnstile?.dispose();
    }
  }

  String? _extractErrorCode(Response<dynamic> response) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data['code'] as String?;
    }
    if (data is String) {
      try {
        final parsed = jsonDecode(data) as Map<String, dynamic>;
        return parsed['code'] as String?;
      } on Exception {
        return null;
      }
    }
    return null;
  }
}
