import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fluxer_app/core/providers/app_ui_lifecycle_provider.dart';
import 'package:fluxer_app/core/providers/gateway_connection_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/talker.dart';
import 'package:fluxer_app/features/gateway/providers/guild_sync_provider.dart';
import 'package:fluxer_app/features/ui/toast/fluxer_toast.dart';
import 'package:fluxer_app/features/ui/toast/toast_provider.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations_en.dart';
import 'package:fluxer_dart/gateway.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gateway_reconnect_provider.g.dart';

const Duration kGatewayReconnectFailureTimeout = Duration(seconds: 30);
const Duration kForegroundStaleReconnectThreshold = Duration(seconds: 30);
const Duration kResumeReconnectDelay = Duration(milliseconds: 500);

final FluxerLocalizationsEn _gatewayL10n = FluxerLocalizationsEn();

/// Waits for the network stack after resume, then nudges the gateway socket.
Future<void> nudgeGatewayReconnectAfterResume(GatewayConnection connection) async {
  await Future<void>.delayed(kResumeReconnectDelay);
  final List<ConnectivityResult> results =
      await Connectivity().checkConnectivity();
  final bool hasConnection = results.any(
    (ConnectivityResult r) => r != ConnectivityResult.none,
  );
  if (!hasConnection) {
    talker.warning('[Gateway] Resume reconnect skipped: no connectivity');
    return;
  }
  talker.info('[Gateway] Resume reconnect starting');
  await connection.reconnectNow();
}

@Riverpod(keepAlive: true)
class GatewayConnectionFailed extends _$GatewayConnectionFailed {
  @override
  bool build() => false;

  void setFailed({required bool value}) {
    state = value;
  }

  void reset() {
    state = false;
  }
}

@Riverpod(keepAlive: true)
Raw<StreamSubscription<GatewayState>?> gatewayStateListener(Ref ref) {
  final connection = ref.watch(gatewayConnectionProvider);
  Timer? failureTimer;

  void clearFailureTimer() {
    failureTimer?.cancel();
    failureTimer = null;
  }

  void markOnline() {
    clearFailureTimer();
    ref.read(serverReachableProvider.notifier).setReachable(value: true);
    ref.read(gatewayConnectionFailedProvider.notifier).reset();
  }

  void markFailed() {
    clearFailureTimer();
    ref.read(serverReachableProvider.notifier).setReachable(value: false);
    ref.read(gatewayConnectionFailedProvider.notifier).setFailed(value: true);
    ref.read(guildSyncProvider.notifier).clearAll();
  }

  void scheduleFailureTimeout() {
    clearFailureTimer();
    failureTimer = Timer(kGatewayReconnectFailureTimeout, () {
      if (connection.state != GatewayState.connected) {
        talker.warning('[Gateway] Reconnect failure timeout reached');
        markFailed();
      }
    });
  }

  final subscription = connection.stateChanges.listen((GatewayState state) {
    switch (state) {
      case GatewayState.connected:
        markOnline();
      case GatewayState.connecting:
      case GatewayState.reconnecting:
        ref.read(serverReachableProvider.notifier).setReachable(value: true);
        final bool onFailureScreen = ref.read(gatewayConnectionFailedProvider);
        if (onFailureScreen) {
          clearFailureTimer();
        } else {
          ref.read(gatewayConnectionFailedProvider.notifier).reset();
          scheduleFailureTimeout();
        }
      case GatewayState.disconnected:
        break;
      case GatewayState.failed:
        talker.error('[Gateway] Fatal gateway close');
        markFailed();
    }
  });

  ref.onDispose(() {
    clearFailureTimer();
    subscription.cancel();
  });
  return subscription;
}

@Riverpod(keepAlive: true)
void gatewayForegroundListener(Ref ref) {
  ref.listen<bool>(appUiForegroundProvider, (bool? previous, bool next) {
    if ((previous ?? true) || !next) {
      return;
    }
    final GatewayConnection connection = ref.read(gatewayConnectionProvider);
    final DateTime? backgroundedAt = ref.read(appLastBackgroundedAtProvider);
    final Duration? backgroundDuration = backgroundedAt != null
        ? DateTime.now().difference(backgroundedAt)
        : null;
    final bool isStaleConnected =
        connection.state == GatewayState.connected &&
        backgroundDuration != null &&
        backgroundDuration > kForegroundStaleReconnectThreshold;
    final bool forceAndroidReconnect =
        Platform.isAndroid &&
        (backgroundDuration == null ||
            backgroundDuration > const Duration(seconds: 5));
    if (forceAndroidReconnect ||
        connection.state != GatewayState.connected ||
        isStaleConnected) {
      talker.info('[Gateway] App resumed, scheduling reconnect');
      unawaited(nudgeGatewayReconnectAfterResume(connection));
    }
  });
}

@Riverpod(keepAlive: true)
void gatewayReconnectToastListener(Ref ref) {
  GatewayState? previousState;
  var reconnectToastShown = false;
  final connection = ref.watch(gatewayConnectionProvider);
  final subscription = connection.stateChanges.listen((GatewayState state) {
    if (ref.read(gatewayConnectionFailedProvider)) {
      previousState = state;
      return;
    }
    final GatewayState? prior = previousState;
    previousState = state;
    if (prior == null) {
      return;
    }
    final bool wasConnected = prior == GatewayState.connected;
    final bool isReconnecting =
        state == GatewayState.connecting ||
        state == GatewayState.reconnecting;
    final bool isConnected = state == GatewayState.connected;
    if (wasConnected && isReconnecting && !reconnectToastShown) {
      reconnectToastShown = true;
      ref.read(toastProvider.notifier).show(
        FluxerToast(
          message: _gatewayL10n.gatewayReconnectingToast,
          duration: const Duration(seconds: 5),
        ),
      );
    }
    if (reconnectToastShown &&
        isConnected &&
        (prior == GatewayState.connecting ||
            prior == GatewayState.reconnecting)) {
      reconnectToastShown = false;
      ref.read(toastProvider.notifier).show(
        FluxerToast(
          message: _gatewayL10n.gatewayConnectedToast,
          variant: FluxerToastVariant.success,
        ),
      );
    }
    if (isConnected) {
      reconnectToastShown = false;
    }
  });

  ref.onDispose(subscription.cancel);
}

@Riverpod(keepAlive: true)
Raw<StreamSubscription<List<ConnectivityResult>>?> connectivityListener(
  Ref ref,
) {
  final connection = ref.watch(gatewayConnectionProvider);

  final subscription = Connectivity().onConnectivityChanged.listen(
    (List<ConnectivityResult> results) {
      final bool hasConnection = results.any(
        (ConnectivityResult r) => r != ConnectivityResult.none,
      );
      if (hasConnection && connection.state != GatewayState.connected) {
        talker.info('[Gateway] Network restored, reconnecting immediately');
        unawaited(connection.reconnectNow());
      }
    },
  );

  ref.onDispose(subscription.cancel);
  return subscription;
}
