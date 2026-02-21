import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fluxer_dart/fluxer_dart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:fluxeron/core/api/captcha_dialog.dart';
import 'package:fluxeron/core/api/captcha_interceptor.dart';
import 'package:fluxeron/core/api/retry_interceptor.dart';
import 'package:fluxeron/core/router/fluxer_router.dart';

part 'fluxer_client_provider.g.dart';

// ignore: do_not_use_environment -- compile-time override for the API base URL
const _kFluxerBaseUrl = String.fromEnvironment('FLUXER_BASE_URL');

@Riverpod(keepAlive: true)
String fluxerBaseUrl(Ref ref) {
  final configuredBaseUrl = _kFluxerBaseUrl.trim();
  if (configuredBaseUrl.isNotEmpty) {
    return configuredBaseUrl;
  }

  return FluxerDart.basePath;
}

@Riverpod(keepAlive: true)
FluxerDart fluxerClient(Ref ref) {
  final baseUrl = ref.watch(fluxerBaseUrlProvider);
  final token = ref.watch(fluxerAuthTokenProvider);

  final client = FluxerDart(basePathOverride: baseUrl);
  client.dio.options.connectTimeout = const Duration(seconds: 15);
  client.dio.options.receiveTimeout = const Duration(seconds: 10);
  if (token != null && token.isNotEmpty) {
    client.setApiKey('sessionToken', token);
  }

  client.dio.interceptors.add(RetryInterceptor(dio: client.dio));
  client.dio.interceptors.add(
    CaptchaInterceptor(
      dio: client.dio,
      showCaptchaDialog: ({required String siteKey, required String baseUrl}) =>
          showCaptchaDialog(
            navigatorKey: rootNavigatorKey,
            siteKey: siteKey,
            baseUrl: baseUrl,
          ),
    ),
  );

  if (kDebugMode) {
    client.dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        logPrint: (object) => debugPrint(object.toString()),
      ),
    );
  }

  return client;
}

/// Holds the current auth token. Set by the auth flow, watched by
/// [fluxerClientProvider] so the client rebuilds when the token changes.
@Riverpod(keepAlive: true)
class FluxerAuthToken extends _$FluxerAuthToken {
  @override
  String? build() => null;

  void setToken(String? token) {
    state = token;
  }
}
