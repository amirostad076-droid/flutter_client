import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:fluxer_app/core/build/push_provider_guard.dart';
import 'package:fluxer_app/core/push/local_push_notifications.dart';
import 'package:fluxer_app/core/push/push_message.dart';
import 'package:fluxer_app/core/push/push_notification_permission.dart';
import 'package:fluxer_app/core/push/push_service.dart';
import 'package:fluxer_app/core/push/unified_push/unified_push_message_mapper.dart';
import 'package:unifiedpush/unifiedpush.dart' as up;

/// Fixed UnifiedPush instance id for this app.
const String kFluxerUnifiedPushInstance = 'fluxer';

const Duration _kEndpointWaitTimeout = Duration(seconds: 3);
const Duration _kEndpointPollInterval = Duration(milliseconds: 100);

class UnifiedPushService implements PushService {
  factory UnifiedPushService() => instance;

  UnifiedPushService._();

  static final UnifiedPushService instance = UnifiedPushService._();

  final StreamController<PushMessage> _messages =
      StreamController<PushMessage>.broadcast();
  final StreamController<up.PushEndpoint> _endpoints =
      StreamController<up.PushEndpoint>.broadcast();

  up.PushEndpoint? _endpoint;
  bool _initialized = false;
  bool _needsDistributorPicker = false;
  String? _pendingVapid;
  static bool _backgroundMode = false;

  Stream<up.PushEndpoint> get endpointStream => _endpoints.stream;

  up.PushEndpoint? get currentEndpoint => _endpoint;

  bool get needsDistributorPicker => _needsDistributorPicker;

  static Future<void> ensureBackgroundInitialized() async {
    if (!PushProviderGuard.isUnifiedPush || !Platform.isAndroid) {
      return;
    }
    _backgroundMode = true;
    await requestPushNotificationPermission();
    await LocalPushNotifications().ensureInitialized();
    await instance._ensureUnifiedPushInitialized();
    await instance.syncRegistration();
  }

  @override
  Future<void> requestPermissions() async {
    await requestPushNotificationPermission();
  }

  @override
  Future<void> initialize() async {
    await initializeWithOptions();
  }

  Future<void> initializeWithOptions({String? vapid}) async {
    if (!PushProviderGuard.isUnifiedPush || !Platform.isAndroid) {
      return;
    }
    if (vapid != null) {
      _pendingVapid = vapid;
    }
    await _ensureUnifiedPushInitialized();
  }

  /// Registers with the saved distributor and waits for an endpoint
  Future<void> syncRegistration({
    bool force = false,
    bool hasPersistedSubscription = false,
  }) async {
    if (!PushProviderGuard.isUnifiedPush || !Platform.isAndroid) {
      return;
    }
    await _ensureUnifiedPushInitialized();
    if (!force &&
        hasPersistedSubscription &&
        _endpoint != null &&
        _endpoint!.url.isNotEmpty) {
      return;
    }
    await _registerWithDistributor();
    if (await _waitForEndpoint()) {
      return;
    }
    if (hasPersistedSubscription && !force) {
      return;
    }
    if (kDebugMode) {
      debugPrint(
        '[UnifiedPushService] no endpoint after register; '
        'unregister+register fallback',
      );
    }
    await unregisterFromDistributor();
    await _registerWithDistributor();
    await _waitForEndpoint();
  }

  Future<void> registerWithSavedDistributor({String? vapid}) async {
    if (!PushProviderGuard.isUnifiedPush || !Platform.isAndroid) {
      return;
    }
    if (vapid != null) {
      _pendingVapid = vapid;
    }
    await up.UnifiedPush.register(
      instance: kFluxerUnifiedPushInstance,
      vapid: _pendingVapid,
    );
    _needsDistributorPicker = false;
  }

  Future<void> unregisterFromDistributor() async {
    if (!PushProviderGuard.isUnifiedPush || !Platform.isAndroid) {
      return;
    }
    await _ensureUnifiedPushInitialized();
    await up.UnifiedPush.unregister(kFluxerUnifiedPushInstance);
    _endpoint = null;
    _needsDistributorPicker = false;
  }

  @override
  Future<String?> getToken() async {
    return _endpoint?.url;
  }

  @override
  Stream<PushMessage> watchMessages() => _messages.stream;

  Future<void> _ensureUnifiedPushInitialized() async {
    if (_initialized) {
      return;
    }
    final bool hasDistributor = await up.UnifiedPush.initialize(
      onNewEndpoint: _onNewEndpoint,
      onRegistrationFailed: _onRegistrationFailed,
      onUnregistered: _onUnregistered,
      onMessage: _onMessage,
    );
    _initialized = true;
    if (hasDistributor) {
      _needsDistributorPicker = false;
    }
  }

  Future<void> _registerWithDistributor() async {
    final String? distributor = await up.UnifiedPush.getDistributor();
    if (distributor != null && distributor.isNotEmpty) {
      await registerWithSavedDistributor();
      return;
    }
    final bool usedDefault =
        await up.UnifiedPush.tryUseCurrentOrDefaultDistributor();
    if (usedDefault) {
      await registerWithSavedDistributor();
      return;
    }
    _needsDistributorPicker = true;
  }

  Future<bool> _waitForEndpoint({
    Duration timeout = _kEndpointWaitTimeout,
  }) async {
    final DateTime deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (_endpoint != null && _endpoint!.url.isNotEmpty) {
        return true;
      }
      await Future<void>.delayed(_kEndpointPollInterval);
    }
    return _endpoint != null && _endpoint!.url.isNotEmpty;
  }

  void _onNewEndpoint(up.PushEndpoint endpoint, String instance) {
    if (instance != kFluxerUnifiedPushInstance) {
      return;
    }
    _endpoint = endpoint;
    _needsDistributorPicker = false;
    _endpoints.add(endpoint);
    if (kDebugMode) {
      debugPrint(
        '[UnifiedPushService] endpoint (temp=${endpoint.temporary}): '
        '${endpoint.url}',
      );
    }
  }

  void _onRegistrationFailed(up.FailedReason reason, String instance) {
    if (instance != kFluxerUnifiedPushInstance) {
      return;
    }
    if (kDebugMode) {
      debugPrint('[UnifiedPushService] registration failed: $reason');
    }
    _onUnregistered(instance);
  }

  void _onUnregistered(String instance) {
    if (instance != kFluxerUnifiedPushInstance) {
      return;
    }
    _endpoint = null;
    if (kDebugMode) {
      debugPrint('[UnifiedPushService] unregistered');
    }
  }

  Future<void> _onMessage(up.PushMessage message, String instance) async {
    if (instance != kFluxerUnifiedPushInstance) {
      return;
    }
    final PushMessage mapped = mapUnifiedPushMessage(message);
    _messages.add(mapped);
    if (kDebugMode) {
      debugPrint(
        '[UnifiedPushService] onMessage decrypted=${message.decrypted} '
        'title=${mapped.title} body=${mapped.body} '
        'bg=$_backgroundMode showLocal=${_shouldShowLocalNotification()}',
      );
    }
    if (!_shouldShowLocalNotification()) {
      return;
    }
    await LocalPushNotifications().ensureInitialized();
    await LocalPushNotifications().showPushMessage(mapped);
  }

  bool _shouldShowLocalNotification() {
    if (_backgroundMode) {
      return true;
    }
    final AppLifecycleState? state = WidgetsBinding.instance.lifecycleState;
    return state != AppLifecycleState.resumed;
  }
}
