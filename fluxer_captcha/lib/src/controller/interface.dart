import 'package:fluxer_captcha/src/captcha_exception.dart';

/// Interface for the Captcha Controller.
abstract class CaptchaController<T> {
  /// The connector associated with this controller.
  late T connector;

  /// Retrieves the current token from the widget.
  ///
  /// Returns `null` if no token is available.
  String? get token;

  /// Retrieves the current widget ID.
  ///
  /// This ID is used to uniquely identify the captcha widget instance.
  String? get widgetId;

  /// Retrieves the widget's ready state.
  ///
  /// Returns `true` if the widget is ready for interaction, otherwise `false`.
  bool get isWidgetReady;

  /// Retrieves the current error state of the captcha widget, if any.
  ///
  /// Returns a [CaptchaException] object if an error exists, otherwise `null`.
  CaptchaException? get error;

  /// Sets a new connector.
  void setConnector(T newConnector);

  /// Sets a new token.
  ///
  /// Use this method to manually set or override the current token value.
  set token(String? token);

  /// Sets the captcha widget ID.
  ///
  /// This assigns a new ID to the current captcha widget instance.
  set widgetId(String? id);

  /// Sets the widget's ready state.
  ///
  /// Use this to indicate whether the widget is ready for interaction.
  set isWidgetReady(bool isReady);

  /// Sets the error state for the captcha widget.
  ///
  /// This method updates the error state of the widget, allowing it to
  /// reflect the current issue encountered.
  set error(CaptchaException? error);

  /// Refreshes the captcha token.
  ///
  /// This method can only be called when [widgetId] is not null.
  Future<void> refreshToken();

  /// Checks if the captcha widget has expired.
  ///
  /// This method can only be called when [widgetId] is not null.
  Future<bool> isExpired();

  /// Registers a callback to be invoked when an error occurs.
  ///
  /// The [callback] function is invoked whenever an error arises in processes
  /// like token fetching or widget initialization.
  void onError(void Function(CaptchaException error) callback);

  /// Registers a callback to be invoked when a new token is successfully
  /// received.
  ///
  /// Use this method to track when new tokens are generated.
  void onTokenReceived(void Function(String token) callback);
}
