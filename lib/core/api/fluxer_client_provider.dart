import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fluxer_app/core/api/captcha_dialog.dart';
import 'package:fluxer_app/core/api/captcha_interceptor.dart';
import 'package:fluxer_app/core/api/retry_interceptor.dart';
import 'package:fluxer_app/core/build/app_build_config.dart';
import 'package:fluxer_app/core/providers/app_runtime_info_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_dart/export.dart';
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
String fluxerUserAgent(Ref ref) {
  final AsyncValue<AppRuntimeInfo> runtime = ref.watch(appRuntimeInfoProvider);
  return runtime.when(
    data: (AppRuntimeInfo info) =>
        'fluxer/${info.version}(${info.buildNumber})/${info.environment.name}',
    loading: () =>
        'fluxer/unknown(0)/${AppBuildConfig.environment.name}',
    error: (Object err, StackTrace stack) =>
        'fluxer/unknown(0)/${AppBuildConfig.environment.name}',
  );
}

@Riverpod(keepAlive: true)
Dio fluxerDio(Ref ref) {
  final baseUrl = ref.watch(fluxerBaseUrlProvider);
  final token = ref.watch(fluxerAuthTokenProvider);
  final userAgent = ref.watch(fluxerUserAgentProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      contentType: 'application/json',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'User-Agent': userAgent,
        'x-fluxer-platform': 'mobile'
      }
    ),
  );

  if (token != null && token.isNotEmpty) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  dio.interceptors.add(RetryInterceptor(dio: dio));
  dio.interceptors.add(
    CaptchaInterceptor(
      dio: dio,
      showCaptchaDialog:
          ({
            required preferredProvider,
            required turnstileSiteKey,
            required hcaptchaSiteKey,
            required baseUrl,
          }) => showCaptchaDialog(
            navigatorKey: rootNavigatorKey,
            preferredProvider: preferredProvider,
            turnstileSiteKey: turnstileSiteKey,
            hcaptchaSiteKey: hcaptchaSiteKey,
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
