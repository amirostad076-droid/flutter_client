import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:fluxer_captcha/src/captcha_exception.dart';
import 'package:fluxer_captcha/src/captcha_provider.dart';
import 'package:fluxer_captcha/src/controller/interface.dart' as i;

/// Captcha controller native (mobile/desktop) implementation.
class CaptchaController extends ChangeNotifier
    implements i.CaptchaController<InAppWebViewController> {
  /// The connector associated with the controller.
  @override
  late InAppWebViewController connector;

  /// The captcha provider this controller is configured for.
  CaptchaProvider provider = CaptchaProvider.turnstile;

  String? _token;

  CaptchaException? _error;

  String? _widgetId = '';

  bool _isReady = false;

  bool _isDisposed = false;

  String get _jsGlobal =>
      provider == CaptchaProvider.turnstile ? 'turnstile' : 'hcaptcha';

  /// Retrieves the current token from the widget.
  ///
  /// Returns `null` if no token is available.
  @override
  String? get token => _token;

  /// Retrieves the current widget ID.
  ///
  /// This ID is used to uniquely identify the captcha widget instance.
  @override
  String? get widgetId => _widgetId;

  /// Retrieves the widget's ready state.
  ///
  /// Returns `true` if the widget is ready for interaction, otherwise `false`.
  @override
  bool get isWidgetReady => _isReady;

  /// Retrieves the current error state of the captcha widget, if any.
  ///
  /// Returns a [CaptchaException] object if an error exists, otherwise `null`.
  @override
  CaptchaException? get error => _error;

  /// Sets a new connector.
  @override
  void setConnector(InAppWebViewController newConnector) {
    connector = newConnector;
  }

  /// Sets a new token.
  ///
  /// Use this method to manually set or override the current token value.
  @override
  set token(String? newToken) {
    if (_token != newToken) {
      _token = newToken;

      if (newToken != null && newToken.isNotEmpty) {
        _onTokenReceived?.call(newToken);
      }

      notifyListeners();
    }
  }

  /// Sets the captcha widget ID.
  ///
  /// This assigns a new ID to the current captcha widget instance.
  @override
  set widgetId(String? id) {
    if (_widgetId != id) {
      _widgetId = id;
      notifyListeners();
    }
  }

  /// Sets the widget's ready state.
  ///
  /// Use this to indicate whether the widget is ready for interaction.
  @override
  set isWidgetReady(bool isReady) {
    if (_isReady != isReady) {
      _isReady = isReady;
      notifyListeners();
    }
  }

  /// Sets the error state for the captcha widget.
  ///
  /// This method updates the error state of the widget, allowing it to
  /// reflect the current issue encountered.
  @override
  set error(CaptchaException? error) {
    _error = error;
    if (error != null) {
      _onError?.call(error);
    }
    notifyListeners();
  }

  /// Refreshes the captcha token.
  ///
  /// This method can only be called when [widgetId] is not null.
  @override
  Future<void> refreshToken() async {
    if (_isDisposed) return;
    _token = null;
    if (!_isReady || _error != null) {
      await connector.reload();
      return;
    }
    await connector
        .evaluateJavascript(source: '''$_jsGlobal.reset(`$_widgetId`);''');
  }

  /// Checks if the captcha widget has expired.
  ///
  /// This method can only be called when [widgetId] is not null.
  @override
  Future<bool> isExpired() async {
    if (_isDisposed ||
        !_isReady ||
        _widgetId == null ||
        token == null ||
        token!.isEmpty) {
      return true;
    }

    if (provider == CaptchaProvider.hcaptcha) {
      final response = await connector.evaluateJavascript(
        source: '''hcaptcha.getResponse(`$_widgetId`);''',
      );
      return response == null || response.toString().isEmpty;
    }

    final result = await connector.evaluateJavascript(
      source: '''turnstile.isExpired(`$_widgetId`);''',
    );

    // JS eval may return a non-bool type; default to expired.
    // ignore: avoid_bool_literals_in_conditional_expressions
    return result is bool ? result : true;
  }

  /// Dispose resources.
  @override
  void dispose() {
    _isDisposed = true;
    _onError = null;
    _onTokenReceived = null;
    super.dispose();
  }

  void Function(CaptchaException error)? _onError;
  void Function(String token)? _onTokenReceived;

  /// Registers a callback to be invoked when an error occurs.
  @override
  void onError(void Function(CaptchaException error) callback) {
    _onError = callback;
  }

  /// Registers a callback to be invoked when a new token is successfully
  /// received.
  @override
  void onTokenReceived(void Function(String token) callback) {
    _onTokenReceived = callback;
  }
}
