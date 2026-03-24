import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fluxer_captcha/fluxer_captcha.dart';
import 'package:fluxeron/core/talker.dart';

/// Error codes the Fluxer API returns when captcha verification is needed.
const _kCaptchaCodes = {'CAPTCHA_REQUIRED', 'INVALID_CAPTCHA'};

/// Key in [RequestOptions.extra] to mark requests made internally by the
/// captcha interceptor (config fetch and retry), preventing re-entrant
/// captcha solving.
const _kCaptchaInternalKey = '_captchaInternal';

/// Captcha configuration extracted from the `.well-known/fluxer` response.
class _CaptchaConfig {
  const _CaptchaConfig({
    required this.preferredProvider,
    required this.turnstileSiteKey,
    required this.hcaptchaSiteKey,
    required this.baseUrl,
  });

  final CaptchaProvider preferredProvider;
  final String? turnstileSiteKey;
  final String? hcaptchaSiteKey;

  /// The webapp URL used as the WebView origin so the captcha provider
  /// recognises the domain against the site key's allowed origins.
  final String baseUrl;

  /// Returns the provider to start with and its site key.
  (CaptchaProvider, String) get initial {
    if (preferredProvider == CaptchaProvider.turnstile &&
        turnstileSiteKey != null) {
      return (CaptchaProvider.turnstile, turnstileSiteKey!);
    }
    if (preferredProvider == CaptchaProvider.hcaptcha &&
        hcaptchaSiteKey != null) {
      return (CaptchaProvider.hcaptcha, hcaptchaSiteKey!);
    }
    if (turnstileSiteKey != null) {
      return (CaptchaProvider.turnstile, turnstileSiteKey!);
    }
    if (hcaptchaSiteKey != null) {
      return (CaptchaProvider.hcaptcha, hcaptchaSiteKey!);
    }
    throw StateError('No captcha provider configured');
  }
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

  /// Callback that shows a visible captcha dialog and returns
  /// the solved token along with the provider that was used.
  /// Used as fallback when invisible mode fails.
  final Future<(String token, CaptchaProvider type)?> Function({
    required CaptchaProvider preferredProvider,
    required String? turnstileSiteKey,
    required String? hcaptchaSiteKey,
    required String baseUrl,
  })
  showCaptchaDialog;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Don't re-enter captcha solving for our own internal requests
    // (config fetch or retry). Without this guard, a failed retry returning
    // INVALID_CAPTCHA would recurse indefinitely.
    if (err.requestOptions.extra[_kCaptchaInternalKey] == true) {
      handler.next(err);
      return;
    }

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

    talker.debug(
      '[CaptchaInterceptor] Challenge received: $code '
      'for ${err.requestOptions.path}',
    );
    unawaited(_solveCaptchaAndRetry(err, handler));
  }

  Future<void> _solveCaptchaAndRetry(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    try {
      final config = await _fetchCaptchaConfig();
      if (config == null) {
        talker.warning('[CaptchaInterceptor] Config fetch returned null');
        handler.next(err);
        return;
      }

      final (provider, siteKey) = config.initial;

      talker.debug('[CaptchaInterceptor] Config: provider=${provider.name}');

      var token = await _solveInvisible(
        provider: provider,
        siteKey: siteKey,
        baseUrl: config.baseUrl,
      );
      talker.debug(
        '[CaptchaInterceptor] Invisible solve: '
        '${token != null ? 'success' : 'failed, trying dialog'}',
      );

      var finalProvider = provider;

      if (token == null) {
        final result = await showCaptchaDialog(
          preferredProvider: provider,
          turnstileSiteKey: config.turnstileSiteKey,
          hcaptchaSiteKey: config.hcaptchaSiteKey,
          baseUrl: config.baseUrl,
        );

        if (result != null) {
          token = result.$1;
          finalProvider = result.$2;
        }
      }

      if (token == null || token.isEmpty) {
        talker.warning('[CaptchaInterceptor] No token obtained');
        handler.next(err);
        return;
      }

      final opts = err.requestOptions;
      opts.headers['X-Captcha-Token'] = token;
      opts.headers['X-Captcha-Type'] = finalProvider.name;
      opts.extra[_kCaptchaInternalKey] = true;

      talker.debug('[CaptchaInterceptor] Retrying with captcha token');
      final retryResponse = await dio.fetch<dynamic>(opts);
      handler.resolve(retryResponse);
    } on DioException catch (retryError) {
      talker.warning(
        '[CaptchaInterceptor] Retry failed: '
        '${retryError.response?.statusCode} ${retryError.message}',
      );
      handler.next(retryError);
      // ignore: avoid_catches_without_on_clauses, WebView errors aren't Exception subtypes
    } catch (e) {
      talker.error('[CaptchaInterceptor] Unexpected error: $e');
      handler.next(err);
    }
  }

  Future<_CaptchaConfig?> _fetchCaptchaConfig() async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/.well-known/fluxer',
        options: Options(extra: {_kCaptchaInternalKey: true}),
      );
      final data = response.data;
      if (data == null) {
        return null;
      }

      final captcha = data['captcha'] as Map<String, dynamic>?;
      if (captcha == null) {
        return null;
      }

      final providerStr = captcha['provider'] as String? ?? 'none';
      if (providerStr == 'none') {
        return null;
      }

      final CaptchaProvider preferredProvider;
      if (providerStr == 'turnstile') {
        preferredProvider = CaptchaProvider.turnstile;
      } else if (providerStr == 'hcaptcha') {
        preferredProvider = CaptchaProvider.hcaptcha;
      } else {
        return null;
      }

      final turnstileKey = captcha['turnstile_site_key'] as String?;
      final hcaptchaKey = captcha['hcaptcha_site_key'] as String?;

      final hasTurnstile = turnstileKey != null && turnstileKey.isNotEmpty;
      final hasHcaptcha = hcaptchaKey != null && hcaptchaKey.isNotEmpty;

      if (!hasTurnstile && !hasHcaptcha) {
        return null;
      }

      final endpoints = data['endpoints'] as Map<String, dynamic>?;
      final baseUrl = endpoints?['webapp'] as String? ?? 'http://localhost';

      return _CaptchaConfig(
        preferredProvider: preferredProvider,
        turnstileSiteKey: hasTurnstile ? turnstileKey : null,
        hcaptchaSiteKey: hasHcaptcha ? hcaptchaKey : null,
        baseUrl: baseUrl,
      );
    } on Exception catch (e) {
      talker.warning('[CaptchaInterceptor] Config fetch error: $e');
      return null;
    }
  }

  Future<String?> _solveInvisible({
    required CaptchaProvider provider,
    required String siteKey,
    required String baseUrl,
  }) async {
    // Invisible mode uses a headless WebView — not available on web.
    if (kIsWeb) {
      return null;
    }

    FluxerCaptcha? captcha;
    try {
      captcha = FluxerCaptcha.invisible(
        provider: provider,
        siteKey: siteKey,
        baseUrl: baseUrl,
      );
      final token = await captcha.getToken();
      return token;
      // ignore: avoid_catches_without_on_clauses, WebView errors aren't Exception subtypes
    } catch (_) {
      return null;
    } finally {
      try {
        await captcha?.dispose();
        // ignore: avoid_catches_without_on_clauses, dispose may fail after renderer crash
      } catch (_) {}
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
