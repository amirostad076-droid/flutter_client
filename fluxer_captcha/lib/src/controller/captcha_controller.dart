export 'impl/facade.dart'
    if (dart.library.io) 'impl/captcha_controller_native.dart'
    if (dart.library.js_interop) 'impl/captcha_controller_web.dart';
