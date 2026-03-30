import 'package:fluxer_dart/gateway.dart';

import 'package:fluxer_app/core/providers/gateway_provider.dart';
import 'package:fluxer_app/core/talker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'guild_sync_provider.g.dart';

@Riverpod(keepAlive: true)
class GuildSync extends _$GuildSync {
  @override
  Set<String> build() => {};

  void syncIfNeeded(String guildId, {bool force = false}) {
    if (!force && state.contains(guildId)) return;

    final connection = ref.read(gatewayConnectionProvider);
    if (connection.state != GatewayState.connected) return;

    try {
      connection.sendLazyRequest(
        subscriptions: {
          guildId: const LazyRequestSubscription(active: true, sync: true),
        },
      );
      state = {...state, guildId};
    } catch (e) {
      talker.warning('[GuildSync] Failed to sync guild $guildId: $e');
    }
  }

  void clearAll() {
    if (state.isEmpty) return;
    state = {};
  }
}
