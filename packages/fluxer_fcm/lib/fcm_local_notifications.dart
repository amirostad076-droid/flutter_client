import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluxer_fcm/fcm_push_message.dart';
import 'package:fluxer_fcm/fcm_push_notification_ids.dart';

/// Background-isolate local notifications for FCM Android builds.
final class FcmLocalNotifications {
  factory FcmLocalNotifications() => _instance;
  FcmLocalNotifications._();
  static final FcmLocalNotifications _instance = FcmLocalNotifications._();

  static const String _channelId = 'fluxer_default_push';
  static const String _channelName = 'Fluxer';
  static const String _channelDescription = 'Messages and alerts';
  static const String _androidNotificationIcon =
      '@drawable/fluxer_logo_monochrome';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<bool> ensureInitialized() async {
    if (_initialized) {
      return true;
    }
    try {
      const InitializationSettings settings = InitializationSettings(
        android: AndroidInitializationSettings(_androidNotificationIcon),
      );
      final bool? ok = await _plugin.initialize(settings: settings);
      _initialized = ok ?? false;
      if (_initialized) {
        await _ensureAndroidChannel();
      }
    } on Object {
      _initialized = false;
      return false;
    }
    return _initialized;
  }

  Future<void> _ensureAndroidChannel() async {
    final AndroidFlutterLocalNotificationsPlugin? android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) {
      return;
    }
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );
    await android.createNotificationChannel(channel);
  }

  Future<void> showPushMessage(FcmPushMessage message) async {
    if (!_initialized) {
      final bool ready = await ensureInitialized();
      if (!ready) {
        if (kDebugMode) {
          debugPrint('[FcmLocalNotifications] show skipped: not initialized');
        }
        return;
      }
    }
    final String title = message.title ?? _channelName;
    final String body = (message.body != null && message.body!.isNotEmpty)
        ? message.body!
        : 'New message';
    final int id = fcmPushMessageNotificationId(message.id);
    final int? badgeCount = parseFcmPushBadgeCount(message.payload);
    final Map<String, String> payloadWithMessageId =
        Map<String, String>.from(message.payload);
    payloadWithMessageId[kFcmLocalNotificationMessageIdKey] = message.id;
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: _androidNotificationIcon,
            number: badgeCount,
          ),
        ),
        payload: jsonEncode(payloadWithMessageId),
      );
    } on Object catch (e, st) {
      if (kDebugMode) {
        debugPrint('[FcmLocalNotifications] show failed: $e\n$st');
      }
    }
  }
}
