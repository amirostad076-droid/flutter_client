import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/providers/gateway_connection_provider.dart';
import 'package:fluxer_app/core/router/route_state_providers.dart';
import 'package:fluxer_app/features/channels/domain/channel.dart';
import 'package:fluxer_app/features/channels/providers/channel_list_view_model.dart';
import 'package:fluxer_app/features/channels/providers/channel_providers.dart';
import 'package:fluxer_dart/gateway.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'member_list_subscription_provider.g.dart';

const int _kMemberListInitialRangeEnd = 99;

@Riverpod(keepAlive: true)
void memberListSubscription(Ref ref) {
  void syncSubscription() {
    final GatewayConnection connection = ref.read(gatewayConnectionProvider);
    if (connection.state != GatewayState.connected) {
      return;
    }
    final bool isMemberListVisible = ref.read(
      channelListViewModelProvider.select(
        (ChannelListState s) => s.isMemberListVisible,
      ),
    );
    if (!isMemberListVisible) {
      return;
    }
    final String? guildId = ref.read(activeGuildIdProvider);
    final String? channelId = ref.read(activeChannelIdProvider);
    if (guildId == null || channelId == null) {
      return;
    }
    final Channel? channel = ref.read(channelByIdProvider(channelId)).value;
    if (channel == null ||
        channel.guildId != guildId ||
        channel.type == ChannelType.voice) {
      return;
    }
    connection.sendLazyRequest(
      subscriptions: <String, LazyRequestSubscription>{
        guildId: LazyRequestSubscription(
          active: true,
          sync: true,
          memberListChannels: <String, List<List<int>>>{
            channelId: <List<int>>[<int>[0, _kMemberListInitialRangeEnd]],
          },
        ),
      },
    );
  }

  ref.listen<String?>(activeGuildIdProvider, (_, _) => syncSubscription());
  ref.listen<String?>(activeChannelIdProvider, (_, _) => syncSubscription());
  ref.listen<bool>(
    channelListViewModelProvider.select(
      (ChannelListState s) => s.isMemberListVisible,
    ),
    (_, _) => syncSubscription(),
  );
  ref.listen<GatewayState>(
    gatewayConnectionProvider.select((GatewayConnection c) => c.state),
    (_, _) => syncSubscription(),
  );
  syncSubscription();
}
