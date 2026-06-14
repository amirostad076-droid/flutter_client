import 'package:dio/dio.dart';
import 'package:fluxer_app/core/api/session_authorization_header.dart';
import 'package:fluxer_app/core/api/skip_auth_interceptor.dart';

class SessionAuthInterceptor extends Interceptor {
  SessionAuthInterceptor({required this.readToken});

  final String? Function() readToken;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (shouldSkipAuth(options)) {
      handler.next(options);
      return;
    }
    final String? token = readToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = formatSessionAuthorizationHeader(
        token,
      );
    } else {
      options.headers.remove('Authorization');
    }
    handler.next(options);
  }
}
