export 'impl/facade.dart'
    if (dart.library.io) 'impl/captcha_widget_native.dart'
    if (dart.library.js_interop) 'impl/captcha_widget_web.dart';
