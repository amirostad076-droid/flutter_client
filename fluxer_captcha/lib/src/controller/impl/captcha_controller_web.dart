import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/material.dart';
import 'package:fluxer_captcha/src/captcha_exception.dart';
import 'package:fluxer_captcha/src/captcha_provider.dart';
import 'package:fluxer_captcha/src/controller/interface.dart' as i;

/// Captcha controller web implementation.
class CaptchaController extends ChangeNotifier
    implements i.CaptchaController<dynamic> {
  /// The connector associated with the controller.
  @override
  late dynamic connector;

  /// The captcha provider this controller is configured for.
  CaptchaProvider provider = CaptchaProvider.turnstile;

  String? _token;

  CaptchaException? _error;

  String? _widgetId = '';

  bool _isReady = false;

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
  void setConnector(dynamic newConnector) {}

  /// Sets a new token.
  ///
  /// Use this method to manually set or override the current token value.
  @override
  set token(String? token) {
    _token = token;

    if (token != null && token.isNotEmpty) {
      _onTokenReceived?.call(token);
    }

    notifyListeners();
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
    globalContext
        .getProperty<JSObject>(_jsGlobal.toJS)
        .callMethod('reset'.toJS, _widgetId?.toJS);
    _token = null;
  }

  /// Checks if the captcha widget has expired.
  ///
  /// This method can only be called when [widgetId] is not null.
  @override
  Future<bool> isExpired() async {
    if (!_isReady || _widgetId == null || token == null || token!.isEmpty) {
      return true;
    }

    final jsObj = globalContext.getProperty<JSObject>(_jsGlobal.toJS);

    if (provider == CaptchaProvider.hcaptcha) {
      final response =
          jsObj.callMethod<JSString>('getResponse'.toJS, _widgetId?.toJS);
      return response.toDart.isEmpty;
    }

    final expired =
        jsObj.callMethod<JSBoolean>('isExpired'.toJS, _widgetId?.toJS);
    return expired.toDart;
  }

  /// Dispose resources.
  @override
  void dispose() {
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
