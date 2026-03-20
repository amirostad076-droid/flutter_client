import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fluxer_dart/export.dart';
import 'package:fluxeron/core/api/captcha_dialog.dart';
import 'package:fluxeron/core/api/captcha_interceptor.dart';
import 'package:fluxeron/core/api/retry_interceptor.dart';
import 'package:fluxeron/core/router/fluxer_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';

part 'fluxer_client_provider.g.dart';

// ignore: do_not_use_environment -- compile-time override for the API base URL
const _kFluxerBaseUrl = String.fromEnvironment('FLUXER_BASE_URL');
const _kDefaultBaseUrl = 'https://api.fluxer.app/v1';

@Riverpod(keepAlive: true)
String fluxerBaseUrl(Ref ref) {
  final configuredBaseUrl = _kFluxerBaseUrl.trim();
  if (configuredBaseUrl.isNotEmpty) {
    return configuredBaseUrl;
  }

  return _kDefaultBaseUrl;
}

@Riverpod(keepAlive: true)
Dio fluxerDio(Ref ref) {
  final baseUrl = ref.watch(fluxerBaseUrlProvider);
  final token = ref.watch(fluxerAuthTokenProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      contentType: 'application/json',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  if (token != null && token.isNotEmpty) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  dio.interceptors.add(RetryInterceptor(dio: dio));
  dio.interceptors.add(
    CaptchaInterceptor(
      dio: dio,
      showCaptchaDialog: ({required String siteKey, required String baseUrl}) =>
          showCaptchaDialog(
            navigatorKey: rootNavigatorKey,
            siteKey: siteKey,
            baseUrl: baseUrl,
          ),
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(
      TalkerDioLogger(
        settings: const TalkerDioLoggerSettings(printResponseTime: true),
      ),
    );
  }

  return dio;
}

@Riverpod(keepAlive: true)
FluxerClient fluxerClient(Ref ref) {
  final dio = ref.watch(fluxerDioProvider);
  final baseUrl = ref.watch(fluxerBaseUrlProvider);
  return FluxerClient(dio, baseUrl: baseUrl);
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
