import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';
import 'package:fluxer_captcha/src/captcha_exception.dart';
import 'package:fluxer_captcha/src/captcha_provider.dart';
import 'package:fluxer_captcha/src/controller/captcha_controller.dart';
import 'package:fluxer_captcha/src/controller/impl/captcha_controller_web.dart'
    as web_ctrl;
import 'package:fluxer_captcha/src/widget/captcha_options.dart';
import 'package:fluxer_captcha/src/widget/interface.dart' as i;
import 'package:web/web.dart' as web;

class _DartCaptcha {
  const _DartCaptcha({
    required this.provider,
    this.onTokenReceived,
    this.onTokenExpired,
    this.onRawError,
    this.onLoaded,
  });

  final CaptchaProvider provider;
  final i.OnTokenReceived? onTokenReceived;
  final i.OnTokenExpired? onTokenExpired;
  final void Function(String code)? onRawError;
  final void Function()? onLoaded;

  String get _jsGlobal =>
      provider == CaptchaProvider.turnstile ? 'turnstile' : 'hcaptcha';

  @JSExport('onTokenReceived')
  void onReceived(JSString token) {
    onTokenReceived?.call(token.toDart);
  }

  @JSExport('onTokenExpired')
  void onExpired() {
    onTokenExpired?.call();
  }

  @JSExport('onTokenError')
  void onError(JSString code) {
    onRawError?.call(code.toDart);
  }

  @JSExport('onCaptchaReady')
  void onReady() {
    onLoaded?.call();
  }

  bool isScriptLoaded() => web.window.hasProperty(_jsGlobal.toJS).toDart;

  void loadScript() {
    if (!isScriptLoaded()) {
      final scriptUrl = switch (provider) {
        CaptchaProvider.turnstile =>
          'https://challenges.cloudflare.com/turnstile/v0/api.js'
              '?render=explicit&onload=onCaptchaReady',
        CaptchaProvider.hcaptcha => 'https://js.hcaptcha.com/1/api.js'
            '?render=explicit&onload=onCaptchaReady',
      };

      final mainScript = web.HTMLScriptElement()
        ..id = 'captcha-script'
        ..async = true
        ..defer = true
        ..src = scriptUrl;

      web.document.head?.append(mainScript);
    }
  }

  web.HTMLDivElement buildWidget({
    required String siteKey,
    required CaptchaOptions options,
    String? action,
    String? cData,
  }) {
    final widget = web.HTMLDivElement()
      ..style.width = '100%'
      ..style.height = '100%'
      ..setAttribute('data-sitekey', siteKey)
      ..setAttribute('data-theme', options.theme.name)
      ..setAttribute('data-size', options.size.name)
      ..setAttribute('data-callback', 'onCaptchaTokenReceived')
      ..setAttribute('data-expired-callback', 'onCaptchaTokenExpired')
      ..setAttribute('data-error-callback', 'onCaptchaError');

    if (provider == CaptchaProvider.turnstile) {
      widget
        ..setAttribute('data-language', options.language)
        ..setAttribute(
          'data-retry',
          options.retryAutomatically ? 'auto' : 'never',
        )
        ..setAttribute(
          'data-retry-interval',
          options.retryInterval.inMilliseconds.toString(),
        )
        ..setAttribute('data-refresh-expired', options.refreshExpired.name)
        ..setAttribute('data-refresh-timeout', options.refreshTimeout.name)
        ..setAttribute('data-feedback-enabled', 'false');

      if (action != null && action.isNotEmpty) {
        widget.setAttribute('data-action', action);
      }

      if (cData != null && cData.isNotEmpty) {
        widget.setAttribute('data-cdata', cData);
      }
    }

    return widget;
  }
}

String _createViewType() {
  final widgetId = '_${DateTime.now().microsecondsSinceEpoch}';
  return '_captcha_$widgetId';
}

String? _renderWidget(CaptchaProvider provider, String target) {
  final jsGlobal = switch (provider) {
    CaptchaProvider.turnstile => 'turnstile',
    CaptchaProvider.hcaptcha => 'hcaptcha',
  };
  final captchaObj = globalContext.getProperty<JSObject>(jsGlobal.toJS);
  final renderFn = captchaObj.getProperty<JSFunction>('render'.toJS);
  final result = renderFn.callAsFunction(captchaObj, target.toJS);
  return (result as JSString?)?.toDart;
}

/// FluxerCaptcha web implementation.
class FluxerCaptcha extends StatefulWidget implements i.FluxerCaptcha {
  /// Create a FluxerCaptcha widget.
  FluxerCaptcha({
    required this.provider,
    required this.siteKey,
    super.key,
    this.action,
    this.cData,
    this.baseUrl = 'http://localhost/',
    CaptchaOptions? options,
    this.controller,
    this.onTokenReceived,
    this.onTokenExpired,
    this.onError,
    this.onTimeout,
  }) : options = options ?? CaptchaOptions() {
    if (provider == CaptchaProvider.turnstile) {
      if (action != null) {
        assert(
          action!.length <= 32 && RegExp(r'^[a-zA-Z0-9_-]*$').hasMatch(action!),
          'action must contain up to 32 characters including _ and -.',
        );
      }

      if (cData != null) {
        assert(
          cData!.length <= 32 && RegExp(r'^[a-zA-Z0-9_-]*$').hasMatch(cData!),
          'cData must contain up to 32 characters including _ and -.',
        );
      }

      assert(
        this.options!.retryInterval.inMilliseconds > 0 &&
            this.options!.retryInterval.inMilliseconds <= 900000,
        'Duration must be greater than 0 and less than or equal to '
        '900000 milliseconds.',
      );
    }
  }

  /// Create an invisible captcha widget.
  ///
  /// [provider] - The captcha provider to use.
  ///
  /// [siteKey] - A captcha sitekey.
  ///
  /// [action] - A customer value that can be used to differentiate widgets
  /// under the same sitekey in analytics and which is returned upon
  /// validation. Turnstile only.
  ///
  /// [cData] - A customer payload that can be used to attach customer data
  /// to the challenge throughout its issuance and which is returned upon
  /// validation. Turnstile only.
  ///
  /// [baseUrl] - A website URL corresponding to the current captcha widget.
  ///
  /// [options] - Configuration options for the captcha widget.
  ///
  /// [onTokenReceived] - A callback invoked upon success of the challenge.
  /// The callback is passed a `token` that can be validated.
  ///
  /// [onTokenExpired] - A callback invoked when the token expires and does
  /// not reset the widget.
  factory FluxerCaptcha.invisible({
    required CaptchaProvider provider,
    required String siteKey,
    String? action,
    String? cData,
    String baseUrl = 'http://localhost',
    i.OnTokenReceived? onTokenReceived,
    i.OnTokenExpired? onTokenExpired,
    i.OnTimeout? onTimeout,
    CaptchaOptions? options,
  }) {
    return _CaptchaInvisible.init(
      provider: provider,
      siteKey: siteKey,
      action: action,
      cData: cData,
      baseUrl: baseUrl,
      onTokenReceived: onTokenReceived,
      onTokenExpired: onTokenExpired,
      onTimeout: onTimeout,
      options: options ?? CaptchaOptions(),
    );
  }

  /// The captcha provider to use.
  @override
  final CaptchaProvider provider;

  /// This [siteKey] is associated with the corresponding widget configuration
  /// and is created upon the widget creation.
  @override
  final String siteKey;

  /// A customer value that can be used to differentiate widgets under the
  /// same sitekey in analytics and which is returned upon validation.
  ///
  /// This can only contain up to 32 alphanumeric characters including _ and -.
  /// Turnstile only.
  @override
  final String? action;

  /// A customer payload that can be used to attach customer data to the
  /// challenge throughout its issuance and which is returned upon validation.
  ///
  /// This can only contain up to 255 alphanumeric characters including _ and -.
  /// Turnstile only.
  @override
  final String? cData;

  /// The base URL of the captcha site.
  ///
  /// Defaults to 'http://localhost/'.
  @override
  final String baseUrl;

  /// Configuration options for the captcha widget.
  ///
  /// If no options are provided, the default [CaptchaOptions] are used.
  @override
  final CaptchaOptions? options;

  /// A controller for managing interactions with the captcha widget.
  @override
  final CaptchaController? controller;

  /// A callback invoked upon success of the challenge.
  /// The callback is passed a `token` that can be validated.
  @override
  final i.OnTokenReceived? onTokenReceived;

  /// A callback invoked when the token expires and does not reset the widget.
  @override
  final i.OnTokenExpired? onTokenExpired;

  /// A callback invoked when there is an error
  /// (e.g., network error or challenge failed).
  @override
  final i.OnError? onError;

  /// Callback invoked when the captcha widget fails to load in time.
  @override
  final i.OnTimeout? onTimeout;

  @override
  State<FluxerCaptcha> createState() => _FluxerCaptchaState();

  /// Retrieves the current token from the widget.
  ///
  /// Returns `null` if no token is available.
  @override
  String? get token => throw UnimplementedError(
        'This function cannot be called in interactive widget mode.',
      );

  /// Retrieves the current widget id.
  ///
  /// This `id` is used to uniquely identify the captcha widget instance.
  @override
  String? get id => throw UnimplementedError(
        'This function cannot be called in interactive widget mode.',
      );

  /// Refreshes the captcha challenge.
  @override
  Future<void> refresh({bool forceRefresh = true}) {
    throw UnimplementedError(
      'This function cannot be called in interactive widget mode.',
    );
  }

  /// Starts a captcha challenge and returns a token, or `null` if the
  /// challenge failed or an error occurred.
  @override
  Future<String?> getToken() {
    throw UnimplementedError(
      'This function cannot be called in interactive widget mode.',
    );
  }

  /// Checks if the captcha widget has expired.
  @override
  Future<bool> isExpired() {
    throw UnimplementedError(
      'This function cannot be called in interactive widget mode.',
    );
  }

  /// Disposes the captcha widget and frees up resources.
  @override
  Future<void> dispose() {
    throw UnimplementedError(
      'This function cannot be called in interactive widget mode.',
    );
  }
}

class _FluxerCaptchaState extends State<FluxerCaptcha> {
  late web.HTMLDivElement _widget;
  late String _widgetViewId;
  late _DartCaptcha _captcha;

  String? widgetId;

  bool _isWidgetReady = false;
  CaptchaException? _hasError;
  Timer? _scriptLoadTimer;
  bool _isDisposed = false;
  bool _viewCreated = false;

  @override
  void initState() {
    super.initState();

    if (widget.controller != null) {
      (widget.controller! as web_ctrl.CaptchaController).provider =
          widget.provider;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _setCaptchaTheme();
      }
    });

    _widgetViewId = _createViewType();
    _captcha = _DartCaptcha(
      provider: widget.provider,
      onTokenReceived: (token) {
        if (_isDisposed) return;
        widget.onTokenReceived?.call(token);
        widget.controller?.token = token;
      },
      onTokenExpired: () {
        if (_isDisposed) return;
        widget.onTokenExpired?.call();
      },
      onRawError: (code) {
        if (_isDisposed) return;
        final exception = switch (widget.provider) {
          CaptchaProvider.turnstile =>
            CaptchaException.fromTurnstileCode(int.tryParse(code) ?? -1),
          CaptchaProvider.hcaptcha => CaptchaException.fromHCaptchaCode(code),
        };
        _addError(exception);
      },
      onLoaded: _onCaptchaLoaded,
    );

    globalContext
      ..setProperty(
        'onCaptchaTokenReceived'.toJS,
        _captcha.onReceived.toJS,
      )
      ..setProperty(
        'onCaptchaTokenExpired'.toJS,
        _captcha.onExpired.toJS,
      )
      ..setProperty(
        'onCaptchaError'.toJS,
        _captcha.onError.toJS,
      )
      ..setProperty(
        'onCaptchaReady'.toJS,
        _captcha.onReady.toJS,
      );

    _widget = _captcha.buildWidget(
      siteKey: widget.siteKey,
      options: widget.options!,
      cData: widget.cData,
      action: widget.action,
    )..className = 'fluxer-captcha_$_widgetViewId';

    _registerView(_widgetViewId);
  }

  void _onCaptchaLoaded() {
    if (_isDisposed || !mounted) return;
    if (_viewCreated) {
      _renderCaptchaWidget();
    }
  }

  void _renderCaptchaWidget() {
    if (_isDisposed || !mounted) return;
    if (widgetId != null) return;

    widgetId = _renderWidget(widget.provider, '.fluxer-captcha_$_widgetViewId');
    widget.controller?.widgetId = widgetId;
    if (mounted) {
      setState(() => _isWidgetReady = true);
    }
    widget.controller?.isWidgetReady = _isWidgetReady;
    _scriptLoadTimer?.cancel();
  }

  void _setCaptchaTheme() {
    if (widget.options!.theme == CaptchaTheme.auto) {
      final brightness = MediaQuery.of(context).platformBrightness;
      final isDark = brightness == Brightness.dark;
      widget.options!.theme = isDark ? CaptchaTheme.dark : CaptchaTheme.light;
    }
  }

  void _registerView(String viewType) {
    ui.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId, {Object? params}) {
        return _widget;
      },
    );
  }

  void _addError(CaptchaException error) {
    if (_isDisposed || !mounted) return;
    setState(() {
      _hasError = error;
      _isWidgetReady = error.retryable;
      widget.controller?.error = error;
      widget.controller?.isWidgetReady = error.retryable;
      widget.onError?.call(error);
    });
  }

  late final Widget _view = HtmlElementView(
    key: widget.key,
    viewType: _widgetViewId,
    onPlatformViewCreated: (id) {
      _viewCreated = true;
      _scriptLoadTimer?.cancel();
      _scriptLoadTimer = Timer(const Duration(milliseconds: 8000), () {
        if (_isDisposed || !mounted) return;
        if (!_isWidgetReady) {
          widget.onTimeout?.call();
        }
      });

      if (_captcha.isScriptLoaded()) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _renderCaptchaWidget();
        });
      } else {
        _captcha.loadScript();
      }
    },
  );

  @override
  void dispose() {
    _isDisposed = true;
    _scriptLoadTimer?.cancel();
    _scriptLoadTimer = null;
    _widget.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _setCaptchaTheme();

    final primaryColor = widget.options!.theme == CaptchaTheme.light
        ? const Color(0xFFFAFAFA)
        : const Color(0xFF232323);
    final secondaryColor = widget.options!.theme == CaptchaTheme.light
        ? const Color(0xFFDEDEDE)
        : const Color(0xFF9A9A9A);
    final adaptiveBorderColor =
        _isWidgetReady ? secondaryColor : Colors.transparent;

    final isErrorResolvable = _hasError != null && _hasError!.retryable;

    final captchaWidget = Visibility(
      visible: _hasError == null || isErrorResolvable,
      child: AnimatedContainer(
        duration: widget.options!.animationDuration!,
        width: _isWidgetReady ? widget.options!.size.width : 0.1,
        height: _isWidgetReady ? widget.options!.size.height : 0.1,
        curve: widget.options!.curves!,
        foregroundDecoration: BoxDecoration(
          border: Border.all(color: adaptiveBorderColor),
          borderRadius: widget.options!.borderRadius,
        ),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: widget.options!.borderRadius!.add(
            const BorderRadius.all(
              Radius.circular(1),
            ),
          ),
        ),
        clipBehavior: Clip.hardEdge,
        child: _view,
      ),
    );

    return captchaWidget;
  }
}

// Mutable fields are required for headless widget state management.
// ignore: must_be_immutable
class _CaptchaInvisible extends FluxerCaptcha {
  _CaptchaInvisible.init({
    required super.provider,
    required super.siteKey,
    super.action,
    super.cData,
    super.baseUrl = 'http://localhost',
    super.onTokenReceived,
    super.onTokenExpired,
    super.onTimeout,
    super.options,
  }) : super(
          controller: CaptchaController(),
        ) {
    _register();
  }

  void _register() {
    if (controller != null) {
      (controller! as web_ctrl.CaptchaController).provider = provider;
    }

    _iframeViewType = _createViewType();
    final captcha = _DartCaptcha(
      provider: provider,
      onTokenReceived: (token) {
        controller?.token = token;
        onTokenReceived?.call(token);
        if (_completer != null && !_completer!.isCompleted) {
          _completer?.complete(token);
        }
      },
      onTokenExpired: () {
        onTokenExpired?.call();
        if (!_completer!.isCompleted) {
          _completer?.complete(null);
        }
      },
      onRawError: (code) {
        final error = switch (provider) {
          CaptchaProvider.turnstile =>
            CaptchaException.fromTurnstileCode(int.tryParse(code) ?? -1),
          CaptchaProvider.hcaptcha => CaptchaException.fromHCaptchaCode(code),
        };
        controller?.error = error;
        if (!_completer!.isCompleted) {
          _completer?.completeError(error);
        }
      },
      onLoaded: () {
        controller?.widgetId = _renderWidget(
          provider,
          '.fluxer-captcha_$_iframeViewType',
        );
        controller?.isWidgetReady = true;
        _scriptLoadTimer?.cancel();
      },
    );

    globalContext
      ..setProperty(
        'onCaptchaTokenReceived'.toJS,
        captcha.onReceived.toJS,
      )
      ..setProperty(
        'onCaptchaTokenExpired'.toJS,
        captcha.onExpired.toJS,
      )
      ..setProperty(
        'onCaptchaError'.toJS,
        captcha.onError.toJS,
      )
      ..setProperty(
        'onCaptchaReady'.toJS,
        captcha.onReady.toJS,
      );

    _widget = captcha.buildWidget(
      siteKey: siteKey,
      options: options!,
      cData: cData,
      action: action,
    )..className = 'fluxer-captcha_$_iframeViewType';

    web.document.body?.append(_widget);
    _scriptLoadTimer?.cancel();
    _scriptLoadTimer = Timer(const Duration(milliseconds: 8000), () {
      if (controller?.isWidgetReady != true) {
        onTimeout?.call();
      }
    });
    captcha.loadScript();

    if (captcha.isScriptLoaded()) {
      controller?.widgetId = _renderWidget(
        provider,
        '.fluxer-captcha_$_iframeViewType',
      );
      controller?.isWidgetReady = true;
    }
  }

  late web.HTMLDivElement _widget;
  late String _iframeViewType;
  Completer<dynamic>? _completer;
  Timer? _scriptLoadTimer;

  @override
  Future<String?> getToken() async {
    _completer = Completer<String?>();

    if (token != null) {
      await controller?.refreshToken();
    }

    return _completer!.future as Future<String?>;
  }

  @override
  String? get id => controller?.widgetId;

  @override
  Future<bool> isExpired() {
    return controller!.isExpired();
  }

  @override
  Future<void> refresh({bool forceRefresh = true}) async {
    if (!controller!.isWidgetReady || forceRefresh) {
      await getToken();
    } else if (controller!.isWidgetReady) {
      _completer = Completer<String?>();

      if (token != null) {
        if (!await controller!.isExpired()) {
          if (!_completer!.isCompleted) {
            _completer?.complete(token);
            return _completer!.future;
          }
        }
      }

      await controller?.refreshToken();
      return _completer!.future;
    }
  }

  @override
  String? get token => controller?.token;

  @override
  Future<void> dispose() async {
    _scriptLoadTimer?.cancel();
    _widget.remove();
  }
}
