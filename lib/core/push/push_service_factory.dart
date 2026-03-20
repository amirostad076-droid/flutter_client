import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:fluxeron/core/build/app_build_config.dart';
import 'package:fluxeron/core/build/push_provider_kind.dart';
import 'package:fluxeron/core/push/push_service.dart';
import 'package:fluxeron/core/push/services/apple_push_service.dart';
import 'package:fluxeron/core/push/services/firebase_messaging_push_service.dart';
import 'package:fluxeron/core/push/services/unified_push_service.dart';

PushService createPushService() {
  if (kIsWeb) {
    return const ApplePushService();
  }
  if (Platform.isIOS) {
    return const ApplePushService();
  }
  if (!Platform.isAndroid) {
    return const ApplePushService();
  }
  if (AppBuildConfig.pushProvider == PushProviderKind.unifiedPush) {
    return const UnifiedPushService();
  }
  if (AppBuildConfig.pushProvider == PushProviderKind.firebaseMessaging) {
    return const FirebaseMessagingPushService();
  }
  return const UnifiedPushService();
}
