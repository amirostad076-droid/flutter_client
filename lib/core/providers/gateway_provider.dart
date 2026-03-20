import 'dart:async';
import 'dart:io';

import 'package:fluxer_dart/gateway.dart';
import 'package:fluxeron/core/api/fluxer_client_provider.dart';
import 'package:fluxeron/core/gateway/gateway_event_handler.dart';
import 'package:fluxeron/core/providers/database_provider.dart';
import 'package:fluxeron/core/talker.dart';
import 'package:fluxeron/features/gateway/providers/gateway_event_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gateway_provider.g.dart';

@Riverpod(keepAlive: true)
GatewayConnection gatewayConnection(Ref ref) {
  final dio = ref.watch(fluxerDioProvider);
  final token = ref.watch(fluxerAuthTokenProvider);

  if (token == null || token.isEmpty) {
    throw StateError('Cannot create gateway connection without auth token');
  }

  final connection = GatewayConnection(
    token: token,
    dio: dio,
    properties: GatewayIdentifyProperties(
      os: Platform.operatingSystem,
      browser: 'fluxeron',
      device: Platform.operatingSystem,
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
    onTypingStart: (channelId, userId) {
      ref.read(typingIndicatorsProvider.notifier).addTyping(channelId, userId);
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
