import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:fluxeron/core/api/fluxer_client_provider.dart';
import 'package:fluxeron/core/gateway/gateway_client.dart';
import 'package:fluxeron/core/providers/database_provider.dart';
import 'package:fluxeron/features/gateway/providers/gateway_event_providers.dart';

part 'gateway_provider.g.dart';

const _kDefaultGatewayUrl = 'wss://gateway.fluxer.app';

@Riverpod(keepAlive: true)
GatewayClient gatewayClient(Ref ref) {
  final db = ref.watch(fluxerDatabaseProvider);
  final baseUrl = ref.watch(fluxerBaseUrlProvider);

  final uri = Uri.parse(baseUrl);
  final gatewayUrl = uri.host.isNotEmpty
      ? 'wss://${uri.host.replaceFirst('api.', 'gateway.')}'
      : _kDefaultGatewayUrl;

  final client = GatewayClient(
    db: db,
    gatewayUrl: gatewayUrl,
    onTypingStart: (channelId, userId) {
      ref.read(typingIndicatorsProvider.notifier).addTyping(channelId, userId);
    },
  );

  ref.onDispose(client.dispose);
  return client;
}
