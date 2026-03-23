import 'package:fluxer_captcha/src/captcha_exception.dart';
import 'package:meta/meta.dart';

/// Interface for the Captcha Controller.
abstract class CaptchaController<T> {
  /// The connector associated with this controller.
  late T connector;

  /// The current captcha token, or `null` if unavailable.
  String? get token;

  /// The captcha widget instance ID.
  String? get widgetId;

  /// Whether the widget is ready for interaction.
  bool get isWidgetReady;

  /// The current error, if any.
  CaptchaException? get error;

  /// Sets a new connector.
  @internal
  void setConnector(T newConnector);

  /// Sets the captcha token manually.
  @internal
  set token(String? token);

  /// Sets the captcha widget ID.
  @internal
  set widgetId(String? id);

  /// Sets the widget's ready state.
  @internal
  set isWidgetReady(bool isReady);

  /// Sets the error state.
  @internal
  set error(CaptchaException? error);

  /// Refreshes the captcha token.
  ///
  /// Can only be called when [widgetId] is not null.
  Future<void> refreshToken();

  /// Checks if the captcha widget has expired.
  ///
  /// Can only be called when [widgetId] is not null.
  Future<bool> isExpired();

  /// Registers a callback for captcha errors.
  void onError(void Function(CaptchaException error) callback);

  /// Registers a callback for new token reception.
  void onTokenReceived(void Function(String token) callback);
}
