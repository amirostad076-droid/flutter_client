import 'package:flutter/material.dart';
import 'package:fluxer_captcha/src/captcha_exception.dart';
import 'package:fluxer_captcha/src/controller/interface.dart' as i;

/// Facade class.
class CaptchaController extends ChangeNotifier
    implements i.CaptchaController<dynamic> {
  /// The connector associated with this controller.
  @override
  late dynamic connector;

  /// Retrieves the current token from the widget.
  ///
  /// Returns `null` if no token is available.
  @override
  String? get token {
    throw UnimplementedError('Cannot call this function on the facade.');
  }

  /// Sets a new connector.
  @override
  void setConnector(dynamic newConnector) {
    throw UnimplementedError('Cannot call this function on the facade.');
  }

  /// Sets a new token.
  ///
  /// Use this method to manually set or override the current token value.
  @override
  set token(String? token) {
    throw UnimplementedError('Cannot call this function on the facade.');
  }

  /// Sets the error state for the captcha widget.
  ///
  /// This method updates the error state of the widget, allowing it to
  /// reflect the current issue encountered.
  @override
  set error(CaptchaException? error) {
    throw UnimplementedError('Cannot call this function on the facade.');
  }

  /// Retrieves the current widget ID.
  ///
  /// This ID is used to uniquely identify the captcha widget instance.
  @override
  String? get widgetId {
    throw UnimplementedError('Cannot call this function on the facade.');
  }

  /// Retrieves the widget's ready state.
  ///
  /// Returns `true` if the widget is ready for interaction, otherwise `false`.
  @override
  bool get isWidgetReady {
    throw UnimplementedError('Cannot call this function on the facade.');
  }

  /// Sets the widget's ready state.
  ///
  /// Use this to indicate whether the widget is ready for interaction.
  @override
  set isWidgetReady(bool isReady) {
    throw UnimplementedError('Cannot call this function on the facade.');
  }

  /// Sets the captcha widget ID.
  ///
  /// This assigns a new ID to the current captcha widget instance.
  @override
  set widgetId(String? id) {
    throw UnimplementedError('Cannot call this function on the facade.');
  }

  /// Retrieves the current error state of the captcha widget, if any.
  ///
  /// Returns a [CaptchaException] object if an error exists, otherwise `null`.
  @override
  CaptchaException? get error {
    throw UnimplementedError('Cannot call this function on the facade.');
  }

  /// Refreshes the captcha token.
  ///
  /// This method can only be called when [widgetId] is not null.
  @override
  Future<void> refreshToken() async {
    throw UnimplementedError('Cannot call this function on the facade.');
  }

  /// Checks if the captcha widget has expired.
  ///
  /// This method can only be called when [widgetId] is not null.
  @override
  Future<bool> isExpired() {
    throw UnimplementedError('Cannot call this function on the facade.');
  }

  /// Registers a callback to be invoked when an error occurs.
  @override
  void onError(void Function(CaptchaException error) callback) {
    throw UnimplementedError('Cannot call this function on the facade.');
  }

  /// Registers a callback to be invoked when a new token is successfully
  /// received.
  @override
  void onTokenReceived(void Function(String token) callback) {
    throw UnimplementedError('Cannot call this function on the facade.');
  }
}
