import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/build/app_build_config.dart';
import 'package:fluxer_app/core/build/push_provider_guard.dart';
import 'package:fluxer_app/core/providers/app_ui_lifecycle_provider.dart';
import 'package:fluxer_app/core/providers/push_provider.dart';
import 'package:fluxer_app/core/push/apns/apns_registration_logic.dart';
import 'package:fluxer_app/core/push/push_notification_permission.dart';
import 'package:fluxer_app/core/push/push_service.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_dart/export.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'apns_mobile_device_registration.g.dart';

@Riverpod(keepAlive: true)
class ApnsMobileDeviceRegistration extends _$ApnsMobileDeviceRegistration {
  static const int _tokenPollAttempts = 30;
  static const Duration _tokenPollDelay = Duration(milliseconds: 200);
  String? _lastRegisteredUserId;
  String? _lastRegisteredTokenHex;
  bool _syncInFlight = false;

  @override
  int build() {
    if (!PushProviderGuard.isApple) {
      return 0;
    }
    ref
      ..listen<String?>(fluxerAuthTokenProvider, (_, _) {
        unawaited(sync());
      })
      ..listen<bool>(authStateProvider, (_, _) {
        unawaited(sync());
      })
      ..listen<String?>(currentUserIdProvider, (
        String? previous,
        String? next,
      ) {
        if (previous != next) {
          unawaited(sync());
        }
      })
      ..listen<bool>(appUiForegroundProvider, (bool? previous, bool next) {
        if (next && previous == false) {
          unawaited(sync());
        }
      });
    SchedulerBinding.instance.addPostFrameCallback((_) {
      unawaited(sync());
    });
    return 0;
  }

  static MobilePushProviderEnvironmentSchema get _providerEnvironment {
    return kDebugMode
        ? MobilePushProviderEnvironmentSchema.development
        : MobilePushProviderEnvironmentSchema.production;
  }

  bool get _shouldRunOnThisPlatform {
    if (kIsWeb) {
      return false;
    }
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return false;
    }
    if (!PushProviderGuard.isApple) {
      return false;
    }
    return true;
  }

  Future<void> sync() async {
    if (!_shouldRunOnThisPlatform) {
      return;
    }
    if (_syncInFlight) {
      return;
    }
    _syncInFlight = true;
    try {
      await _syncImpl();
    } finally {
      _syncInFlight = false;
    }
  }

  Future<void> _syncImpl() async {
    final String? bearer = ref.read(fluxerAuthTokenProvider);
    if (bearer == null || bearer.isEmpty) {
      return;
    }
    if (!ref.read(authStateProvider)) {
      return;
    }
    final String? userId = ref.read(currentUserIdProvider);
    if (userId == null || userId.isEmpty) {
      return;
    }
    final bool granted = await requestPushNotificationPermission();
    if (!granted) {
      if (kDebugMode) {
        debugPrint('[ApnsMobileDeviceRegistration] notifications not granted');
      }
      return;
    }
    final PushService push = ref.read(pushServiceProvider);
    try {
      await push.initialize();
    } on Object catch (e, st) {
      if (kDebugMode) {
        debugPrint('[ApnsMobileDeviceRegistration] initialize failed: $e\n$st');
      }
      return;
    }
    String? hex;
    for (var attempt = 0; attempt < _tokenPollAttempts; attempt++) {
      hex = await push.getToken();
      if (hex != null && hex.isNotEmpty) {
        break;
      }
      await Future<void>.delayed(_tokenPollDelay);
    }
    if (hex == null || hex.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[ApnsMobileDeviceRegistration] No APNs token after polling',
        );
      }
      return;
    }
    if (shouldSkipApnsRegistration(
      currentUserId: userId,
      tokenHex: hex,
      lastRegisteredUserId: _lastRegisteredUserId,
      lastRegisteredTokenHex: _lastRegisteredTokenHex,
    )) {
      return;
    }
    try {
      await ref
          .read(fluxerClientProvider)
          .users
          .registerMobilePushDevice(
            body: RegisterMobileDeviceRequest(
              platform: RegisterMobileDeviceRequestPlatformPlatform.iosApns,
              token: hex,
              userAgent: ref.read(fluxerClientPropertiesProvider).userAgent,
              appId: AppBuildConfig.mobilePushAppId,
              providerEnvironment: _providerEnvironment,
            ),
          );
      _lastRegisteredUserId = userId;
      _lastRegisteredTokenHex = hex;
      if (kDebugMode) {
        debugPrint(
          '[ApnsMobileDeviceRegistration] registered token for user $userId',
        );
      }
    } on DioException catch (e, st) {
      if (kDebugMode) {
        debugPrint('[ApnsMobileDeviceRegistration] register failed: $e\n$st');
      }
    }
  }

  Future<void> unregisterCurrentToken() async {
    if (!_shouldRunOnThisPlatform) {
      return;
    }
    String? hex = _lastRegisteredTokenHex;
    if (hex == null || hex.isEmpty) {
      hex = await ref.read(pushServiceProvider).getToken();
    }
    if (hex == null || hex.isEmpty) {
      return;
    }
    final String? bearer = ref.read(fluxerAuthTokenProvider);
    if (bearer == null || bearer.isEmpty) {
      return;
    }
    try {
      await ref
          .read(fluxerClientProvider)
          .users
          .unregisterMobilePushDevice(
            body: UnregisterMobileDeviceRequest(
              platform: UnregisterMobileDeviceRequestPlatformPlatform.iosApns,
              token: hex,
              appId: AppBuildConfig.mobilePushAppId,
              providerEnvironment: _providerEnvironment,
            ),
          );
      _lastRegisteredUserId = null;
      _lastRegisteredTokenHex = null;
    } on DioException catch (e, st) {
      if (kDebugMode) {
        debugPrint('[ApnsMobileDeviceRegistration] unregister failed: $e\n$st');
      }
    }
  }
}
