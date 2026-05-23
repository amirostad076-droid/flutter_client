import 'dart:io';

import 'package:fluxer_app/core/build/push_provider_guard.dart';
import 'package:fluxer_fcm/fcm_main_bootstrap.dart';

void bootstrapFcmIfNeeded() {
  if (!PushProviderGuard.isFirebaseMessaging || !Platform.isAndroid) {
    return;
  }
  registerFcmBackgroundHandler();
}
