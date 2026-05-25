import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:fluxer_fcm/fcm_message_mapper.dart';
import 'package:fluxer_fcm/fcm_push_message.dart';
import 'package:fluxer_fcm/firebase_options.dart';

class FluxerFcmPushService {
  factory FluxerFcmPushService() => instance;

  FluxerFcmPushService._();

  static final FluxerFcmPushService instance = FluxerFcmPushService._();

  final StreamController<FcmPushMessage> _messages =
      StreamController<FcmPushMessage>.broadcast();
  final StreamController<String> _tokenRefresh =
      StreamController<String>.broadcast();

  bool _initialized = false;
  void Function(Map<String, String> payload)? _onNotificationTap;
  Map<String, String>? _pendingNotificationTapPayload;

  Stream<String> get tokenRefreshStream => _tokenRefresh.stream;

  void setNotificationTapCallback(
    void Function(Map<String, String> payload)? callback,
  ) {
    _onNotificationTap = callback;
    if (callback == null) {
      return;
    }
    final Map<String, String>? pendingPayload = _pendingNotificationTapPayload;
    if (pendingPayload == null) {
      return;
    }
    _pendingNotificationTapPayload = null;
    callback(pendingPayload);
  }

  Future<void> requestPermissions() async {
    final NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission();
    if (kDebugMode) {
      debugPrint('[FluxerFcmPushService] permission: ${settings.authorizationStatus}');
    }
  }

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);
    FirebaseMessaging.instance.onTokenRefresh.listen((String token) {
      if (token.isNotEmpty) {
        _tokenRefresh.add(token);
      }
    });
    final RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _dispatchTap(initialMessage);
    }
    _initialized = true;
    if (kDebugMode) {
      debugPrint('[FluxerFcmPushService] initialized');
    }
  }

  Future<String?> getToken() async {
    return FirebaseMessaging.instance.getToken();
  }

  Stream<FcmPushMessage> watchMessages() => _messages.stream;

  void _onForegroundMessage(RemoteMessage message) {
    final FcmPushMessage mapped = mapRemoteMessage(message);
    if (kDebugMode) {
      debugPrint('[FluxerFcmPushService] foreground id=${mapped.id}');
    }
    _messages.add(mapped);
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    _dispatchTap(message);
  }

  void _dispatchTap(RemoteMessage message) {
    final FcmPushMessage mapped = mapRemoteMessage(message);
    _dispatchTapPayload(mapped.payload);
  }

  void _dispatchTapPayload(Map<String, String> payload) {
    final void Function(Map<String, String> payload)? callback =
        _onNotificationTap;
    if (callback != null) {
      callback(payload);
      return;
    }
    _pendingNotificationTapPayload = Map<String, String>.unmodifiable(payload);
  }

  @visibleForTesting
  void dispatchTapPayloadForTesting(Map<String, String> payload) {
    _dispatchTapPayload(payload);
  }

  @visibleForTesting
  void resetForTesting() {
    _initialized = false;
    _onNotificationTap = null;
    _pendingNotificationTapPayload = null;
  }
}
