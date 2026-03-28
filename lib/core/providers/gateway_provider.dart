import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fluxer_dart/gateway.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/gateway/gateway_event_handler.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/router/route_state_providers.dart';
import 'package:fluxer_app/core/talker.dart';
import 'package:fluxer_app/features/gateway/providers/gateway_event_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gateway_provider.g.dart';

@Riverpod(keepAlive: true)
GatewayConnection gatewayConnection(Ref ref) {
  final dio = ref.watch(fluxerDioProvider);
  final token = ref.watch(fluxerAuthTokenProvider);

  if (token == null || token.isEmpty) {
    throw StateError('Cannot create gateway connection without auth token');
  }

  final isDesktop = Platform.isLinux || Platform.isMacOS || Platform.isWindows;

  final activeGuildId = ref.read(activeGuildIdProvider);

  final connection = GatewayConnection(
    token: token,
    dio: dio,
    initialGuildId: activeGuildId,
    properties: GatewayIdentifyProperties(
      os: Platform.operatingSystem,
      browser: 'fluxer_app',
      device: Platform.operatingSystem,
      osVersion: Platform.operatingSystemVersion,
      locale: Platform.localeName,
      browserVersion: '1.0.0',
      desktopAppVersion: isDesktop ? '1.0.0' : null,
      desktopOs: isDesktop ? Platform.operatingSystem : null,
    ),
  );

  ref.onDispose(connection.dispose);
  return connection;
}

@Riverpod(keepAlive: true)
Raw<StreamSubscription<GatewayEvent>?> gatewayEventListener(Ref ref) {
  final db = ref.watch(fluxerDatabaseProvider);
  final connection = ref.watch(gatewayConnectionProvider);

  final handler = GatewayEventHandler(
    database: db,
    onReady: () {
      talker.info('[Gateway] Setting gatewayReady = true');
      ref.read(gatewayReadyProvider.notifier).setReady();
    },
    onTypingStart: (channelId, userId) {
      ref.read(typingIndicatorsProvider.notifier).addTyping(channelId, userId);
    },
    onTypingClear: (channelId, userId) {
      ref
          .read(typingIndicatorsProvider.notifier)
          .removeTyping(channelId, userId);
    },
    onVoiceStateUpdate: (state) {
      ref.read(voiceStatesMapProvider.notifier).update(state);
    },
    onVoiceStatesBulk: (states) {
      ref.read(voiceStatesMapProvider.notifier).updateBulk(states);
    },
    onCallCreate: (event) {
      ref
          .read(activeCallsProvider.notifier)
          .createCall(
            event.channelId,
            messageId: event.messageId,
            region: event.region,
            ringing: event.ringing,
            voiceStates: event.voiceStates,
          );
    },
    onCallUpdate: (event) {
      ref
          .read(activeCallsProvider.notifier)
          .updateCall(
            event.channelId,
            messageId: event.messageId,
            region: event.region,
            ringing: event.ringing,
            voiceStates: event.voiceStates,
          );
    },
    onCallDelete: (channelId) {
      ref.read(activeCallsProvider.notifier).deleteCall(channelId);
    },
    onInviteCreate: (data) {
      ref.read(inviteCacheProvider.notifier).addInvite(data);
    },
    onInviteDelete: (code) {
      ref.read(inviteCacheProvider.notifier).removeInvite(code);
    },
  );

  final subscription = connection.events.listen(
    handler.handle,
    onError: (Object error) {
      talker.error('[Gateway] Event stream error: $error');
    },
  );

  ref.onDispose(subscription.cancel);
  return subscription;
}

@Riverpod(keepAlive: true)
Raw<StreamSubscription<GatewayState>?> gatewayStateListener(Ref ref) {
  final connection = ref.watch(gatewayConnectionProvider);

  final subscription = connection.stateChanges.listen((state) {
    final reachable = ref.read(serverReachableProvider.notifier);
    switch (state) {
      case GatewayState.connected:
        reachable.setReachable(value: true);
      case GatewayState.disconnected:
        reachable.setReachable(value: false);
      case GatewayState.connecting:
      case GatewayState.reconnecting:
        break;
    }
  });

  ref.onDispose(subscription.cancel);
  return subscription;
}

/// Monitors network connectivity and triggers immediate gateway reconnect
/// when the device comes back online.
@Riverpod(keepAlive: true)
Raw<StreamSubscription<List<ConnectivityResult>>?> connectivityListener(
  Ref ref,
) {
  final connection = ref.watch(gatewayConnectionProvider);

  final subscription = Connectivity().onConnectivityChanged.listen((results) {
    final hasConnection = results.any((r) => r != ConnectivityResult.none);

    if (hasConnection && connection.state == GatewayState.disconnected) {
      talker.info('[Gateway] Network restored, reconnecting immediately');
      unawaited(connection.connect());
    }
  });

  ref.onDispose(subscription.cancel);
  return subscription;
}
