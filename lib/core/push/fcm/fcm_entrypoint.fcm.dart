import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:fluxer_app/core/build/push_provider_guard.dart';
import 'package:fluxer_app/core/push/fcm/fcm_background_handler_policy.dart';
import 'package:fluxer_app/core/push/fcm/fcm_pending_notification_tap.dart';
import 'package:fluxer_app/core/push/fcm/fcm_tap_payload_cache.dart';
import 'package:fluxer_fcm/fluxer_fcm_bootstrap.dart';

Future<void> bootstrapFcmIfNeeded() async {
  if (!PushProviderGuard.isFirebaseMessaging || !Platform.isAndroid) {
    return;
  }
  try {
    FluxerFcmBootstrap.configure(
      enrichTapPayload: FcmTapPayloadCache.enrich,
      shouldSaveTapPayloadCache: shouldSaveFcmTapPayloadCache,
      saveTapPayloadCache: FcmTapPayloadCache.save,
      onBackgroundNotificationTap: FcmPendingNotificationTap.save,
    );
    await FluxerFcmBootstrap.bootstrapIfNeeded();
  } on Object catch (error, stackTrace) {
    if (kDebugMode) {
      debugPrint('[FCM] bootstrapIfNeeded failed: $error\n$stackTrace');
    }
    rethrow;
  }
}

Future<void> bootstrapFcmAfterRunApp() async {
  if (!PushProviderGuard.isFirebaseMessaging || !Platform.isAndroid) {
    return;
  }
  try {
    await FluxerFcmBootstrap.bootstrapAfterRunApp();
  } on Object catch (error, stackTrace) {
    if (kDebugMode) {
      debugPrint('[FCM] bootstrapAfterRunApp failed: $error\n$stackTrace');
    }
    rethrow;
  }
}
