import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:fluxer_app/core/deep_links/deep_link_handler.dart';
import 'package:fluxer_app/core/push/push_notification_path_resolver.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'push_notification_tap_handler.g.dart';

@Riverpod(keepAlive: true)
class PushNotificationTapHandler extends _$PushNotificationTapHandler {
  @override
  void build() {}

  void handlePayloadJson(String? payloadJson) {
    if (payloadJson == null || payloadJson.isEmpty) {
      return;
    }
    try {
      final Object? decoded = jsonDecode(payloadJson);
      if (decoded is! Map<String, dynamic>) {
        return;
      }
      final Map<String, String> payload = decoded.map(
        (String key, dynamic value) =>
            MapEntry<String, String>(key, value?.toString() ?? ''),
      );
      handlePayload(payload);
    } on Object catch (e, st) {
      if (kDebugMode) {
        debugPrint('[PushNotificationTap] payload parse failed: $e\n$st');
      }
    }
  }

  void handlePayload(Map<String, String> payload) {
    final String? path = resolvePushNotificationPath(payload);
    if (path == null) {
      if (kDebugMode) {
        debugPrint('[PushNotificationTap] no navigable path in $payload');
      }
      return;
    }
    ref.read(deepLinkHandlerProvider.notifier).handlePath(path);
  }
}
